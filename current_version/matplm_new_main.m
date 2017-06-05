function [plm_outputs, varargout] = matplm_new_main(varargin)
%% [plm_outputs] = matplm_new_main(psg_struct)
% The main driving function for the MATPLM program. Returns a structure of
% arrays with descriptions of PLMS and other, more general movements.
%
% inputs:
%   - psg_struct - the subject structure, output from edf conversion stuff
%
% optional inputs:
%   - 'separate_legs' - process each leg channel individually, affects
%   outputs
%   - 'default_params' - don't ask for inputs, just use the defaults (see
%   'getInput2.m' for the default options.
%
% optional outputs:
%   [plm_outputs, lEMG] = ..., filtered and rect left leg channel
%   [plm_outputs, lEMG, rEMG] = ..., right leg channel

p = inputParser;
p.CaseSensitive = false;

p.addParameter('psg_struct',struct());
p.addParameter('separate_legs',false,@islogical);

buttonval = @(x) assert(strcmp(x,'Standard') || strcmp(x,'Most Recent')...
    || strcmp(x,'New'));
p.addParameter('button','ask',buttonval);

p.parse(varargin{:})

if isempty(p.Results.psg_struct)
   [filename, filepath] = uigetfile('*.mat', 'Open a patient file:' );
   psg_struct = load(fullfile(filepath,filename));
   psg_struct = psg_struct.(char(fieldnames(psg_struct)));
else
    psg_struct = p.Results.psg_struct;
end

if p.Results.separate_legs
    display('MATPLM will calculate CLM/PLM for each leg separately');
    sep_flag = 1;
else
    sep_flag = 0;
end

tformat = 'yyyy-mm-dd HH:MM:SS.fff';
plm_outputs = struct();
%% Extract necessary data from structure
% find the LAT and RAT channels in the structure
% TODO: support different channel naming styles
%   solution: add these names when we convert
lbls = extractfield(psg_struct.Signals,'label');
lidx = find(not(cellfun('isempty', strfind(lbls,'Left'))));
ridx = find(not(cellfun('isempty', strfind(lbls,'Right'))));

lEMG = psg_struct.Signals(lidx(1)).data;
rEMG = psg_struct.Signals(ridx(1)).data;

% automatically gets sampling rate, as long as it is recorded in the .EDF
% Unless the user specifies 'default_params', ask for them.
if strcmp(p.Results.button,'ask')
    button = questdlg(['Please specify which scoring options you would '...
        'like to use'],'Scoring Options','Standard','Most Recent','New',...
        'Most Recent');
    if isempty(button), error('Scoring option window closed'); end
else
    button = p.Results.button;
end

switch button
    case 'Standard'
        load('standard_defaults.mat');
    case 'Most Recent'
        load('last_used_defaults.mat')
    case 'New'
        [last_used, quit] = getInput2(psg_struct.Signals(ridx(1)).frq,true);
        if quit, return; end
        save('last_used_defaults.mat','last_used');
end

% find hypnogram/apnea/arousal vectors, start and stop times (in data
% points) of the actual sleep scoring and the clock time start. The
% hypnogram is expected to use standard 30 sec epochs.
[epochStage,rec_start,rec_end,apnea_data,arousal_data,start_time] = ...
    errcheck_ss(psg_struct,lEMG,rEMG,last_used.fs);

%% Filter and rectify data. Optionally apply dynamic threshold
% Truncate, filter and rectify EMG signals.
lEMG = butter_rect(last_used,lEMG,rec_start,rec_end,'rect');
rEMG = butter_rect(last_used,rEMG,rec_start,rec_end,'rect');

%% Calculate leg movements for each leg channel
% Find all leg movements on the left and right legs.

% Also note the '+6' after *minT: the high threshold is traditionally 8
% microvolts above the noise (or 6 above the low threshold)
t = [lEMG * 0, rEMG * 0];
[lLM, tmp] = new_indices(lEMG,last_used); t(:,1) = tmp(:,1);
[rLM, tmp] = new_indices(rEMG,last_used); t(:,2) = tmp(:,1);
clear tmp

% flag sections where one leg has higher noise than the other
t(:,3) = t(:,1) - t(:,2);
% some rough parameters for accessing threshold differences
suspect_ratio = 15; suspect_time = 30;
if size(find(abs(t(:,3)) > suspect_ratio),1) > suspect_time * last_used.fs
    display(['CAUTION: there is a significant difference in threshold ',...
        'between legs. Visual inspection is recommended to rule out noise']);
end

% we always want these in the output array
plm_outputs.lLM = lLM;
plm_outputs.rLM = rLM;

%% Calculate candidate LMs and PLMs for combined/separate legs
% Here is where things diverge if the user specifies 'separate_legs'

if sep_flag == 0
    % calculate PLM candidates by combining the legs
%     CLM = candidate_lms_old(rLM,lLM,epochStage,params,apnea_data,...
%         arousal_data,start_time);
    [CLM,CLMnr] = candidate_lms(rLM,lLM,epochStage,last_used,tformat,...
        apnea_data,arousal_data,start_time);
%     [PLM,~] = periodic_lms(CLM,params);
%     [~,ia,~] = intersect(CLM(:,1),PLM(:,1));
%     CLM(ia,5) = 1; % go back and mark PLM in CLM
    
    % store output vectors in struct
    plm_outputs.CLMnr = CLMnr;
    plm_outputs.CLM = CLM;
    
    % Remember to do one without apnea events
    plm_outputs.PLMnr = periodic_lms(CLMnr,last_used);
    plm_outputs.PLM = periodic_lms(CLM,last_used);
    plm_outputs.arousals = arousal_data;
    plm_outputs.apneas = apnea_data;


else % WARNING - this may not play nicely with the reporting...
    % get CLM from each leg seperately    
%     lCLM = candidate_lms_rev2([],lLM,epochStage,params,apnea_data,...
%         arousal_data,start_time);
%     rCLM = candidate_lms_rev2(rLM,[],epochStage,params,apnea_data,...
%         arousal_data,start_time);
    lCLM = candidate_lms([],lLM,epochStage,last_used,apnea_data,...
        arousal_data,start_time);
    rCLM = candidate_lms(rLM,[],epochStage,last_used,apnea_data,...
        arousal_data,start_time);
    
    [lPLM,~] = periodic_lms(lCLM,last_used);
    [~,ia,~] = intersect(lCLM(:,1),lPLM(:,1));
    lCLM(ia,5) = 1; 
    [rPLM,~] = periodic_lms(rCLM,last_used);
    [~,ia,~] = intersect(rCLM(:,1),rPLM(:,1));    
    rCLM(ia,5) = 1;
    
    % store output vectors in struct
    plm_outputs.lCLM = lCLM;
    plm_outputs.lPLM = lPLM;
    plm_outputs.lPLMS = lPLM(lPLM(:,6) > 0,:);
    plm_outputs.lCLMS = lCLM(lCLM(:,6) > 0,:);
    
    plm_outputs.rCLM = rCLM;
    plm_outputs.rPLM = rPLM;
    plm_outputs.rPLMS = rPLM(rPLM(:,6) > 0,:);
    plm_outputs.rCLMS = rCLM(rCLM(:,6) > 0,:);
end

plm_outputs.hypnostart = psg_struct.CISRE_HypnogramStart;
plm_outputs.epochstage = epochStage;
plm_outputs.column_headers = {'Start','End','Duration','IMI','isPLM','SleepStage',...
    'Start_in_Min','StartEpoch','Breakpoint','Area','isApnea','isArousal',...
    'Lateraltiynessment'};
plm_outputs.fs = last_used.fs;

poss_outs = {'lEMG', 'rEMG','t'};
nout = max(nargout,1) - 1;
for k = 1:nout
    varargout{k} = eval(poss_outs{k});
end

end

function [es,ss,se,apd,ard,hgs] = errcheck_ss(psg_struct,LAT,RAT,fs)
%% [es,ss,se] = errcheck_ss(psg_struct,LAT,RAT,fs)
% Extracts and handles epochStage vector (es), start and end of the
% sleep record (ss/se), apnea/arousal vectors (apd/ard) and hynogram start
% time (hgs).
%
% Don't worry about this function, it's just internal and kind of nonsense
% otherwise

% Get sleep start and end
try
    ss = round(psg_struct.EDFStart2HypnoInSec) * fs + 1;
catch
    warning('Reference to non-existent field ''EDFStart2HypnoInSec''');
    ss = 1;
end

% Get sleep end and hypnogram
try
    es = psg_struct.CISRE_Hypnogram;
    se = ss + size(es, 1) * 30 * fs;
    
catch
    warning(['Reference to non-existent field ''CISRE_Hypnogram''... ',...
        'Assuming (possibly incorrectly) that TST < 8 hours... ',...
        'Sleep staging information will be unavailable']);
    
    se = ss + 960 * 30 * fs;
    es = zeros(960,1);
end

% Get apnea, arousal data
try
    apd = psg_struct.CISRE_Apnea;   
catch
    warning('Reference to non-existent field ''CISRE_Apnea''');
    apd = {0,0,0};
end

try
    ard = psg_struct.CISRE_Arousal;   
catch
    warning('Reference to non-existent field ''CISRE_Arousal''');
    ard = {0,0,0};
end

try
    hgs = psg_struct.CISRE_HypnogramStart;
catch
    warning('Reference to non-existent field ''CISRE_HypnogramStart''');
    hgs = '2000-01-01 00:00:00';
end

% Make sure the sleep record end (from size of hypnogram) is not beyond the
% end of the EMG recording. The two channels should always be the same
% length, but check to make sure.
if se >= max(size(RAT,1),size(LAT,1))
    se = min(size(RAT,1),size(LAT,1)); 
end

% If there are any NaNs in the record, filtering will fail. We must end the
% record when a NaN is found
if size(find(isnan(LAT(ss:se)),1)) > 0
    se = ss + find(isnan(LAT(ss:se)),1) - 2; 
end 
if size(find(isnan(RAT(ss:se)),1)) > 0
    se = ss + find(isnan(RAT(ss:se)),1) - 2; 
end 

end