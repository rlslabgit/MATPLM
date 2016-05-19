function [plm_outputs,lEMG,rEMG, EKG] = matplm_new_main_rev1(psg_struct,varargin)
%% [plm_outputs] = matplm_new_main(psg_struct)
% The main driving function for the MATPLM program. Input is the full
% subject structure, transferred from EDF format with EDF
% Conversion/Generic_Convert.m. This version uses 'new_indices', which does
% not give the option to apply DT, morph or EKG, but does it anyway.


%TODO: use varargout for readibility and extra use


sep_flag = 0;
plm_outputs = struct();

if isempty(psg_struct)
   [filename, filepath] = uigetfile('*.mat', 'Open a patient file:' );
   psg_struct = load(fullfile(filepath,filename));
   psg_struct = psg_struct.(char(fieldnames(psg_struct)));
end

if strcmp('separate_legs',varargin)
    display('MATPLM will calculate CLM/PLM for each leg separately');
    sep_flag = 1;
end


%% Extract necessary data from structure
% find the LAT and RAT channels in the structure
% TODO: support different channel naming styles
lbls = extractfield(psg_struct.Signals,'label');
lidx = find(not(cellfun('isempty', strfind(lbls,'Left'))));
ridx = find(not(cellfun('isempty', strfind(lbls,'Right'))));
kidx = find(not(cellfun('isempty', strfind(lbls,'EKG'))));

lEMG = psg_struct.Signals(lidx(1)).data;
rEMG = psg_struct.Signals(ridx(1)).data;
EKG = psg_struct.Signals(kidx(1)).data;

% automatically gets sampling rate, as long as it is recorded in the .EDF
% Unless the user specifies 'default_params', ask for them.
if strcmp('default_params',varargin)
    [params, quit] = getInput2(psg_struct.Signals(ridx(1)).frq,false);
    if quit
        return
    end
else
    [params, quit] = getInput2(psg_struct.Signals(ridx(1)).frq,true);
    if quit
        return
    end
end

% find hypnogram/apnea/arousal vectors, start and stop times (in data
% points) of the actual sleep scoring and the clock time start. The
% hypnogram is expected to use standard 30 sec epochs.
[epochStage,rec_start,rec_end,apnea_data,arousal_data,start_time] = ...
    errcheck_ss(psg_struct,lEMG,rEMG,params.fs);

%% Filter and rectify data. Optionally apply dynamic threshold
% Truncate, filter and rectify EMG signals.
lEMG = butter_rect(params,lEMG,rec_start,rec_end);
rEMG = butter_rect(params,rEMG,rec_start,rec_end);

EKG = butter_rect(struct('hipass',0.5,'lopass',40,'fs',500),EKG,rec_start,rec_end);

%% Calculate leg movements for each leg channel
% Find all leg movements on the left and right legs.

% Also note the '+6' after *minT: the high threshold is traditionally 8
% microvolts above the noise (or 6 above the low threshold)
lLM = new_indices_rev1(lEMG,params.fs);
rLM = new_indices_rev1(rEMG,params.fs);

% we always want these in the output array
plm_outputs.lLM = lLM;
plm_outputs.rLM = rLM;

%% Calculate candidate LMs and PLMs for combined/separate legs
% Here is where things diverge if the user specifies 'separate_legs'

if sep_flag == 0
    % calculate PLM candidates by combining the legs
    CLM = candidate_lms_rev1(rLM,lLM,epochStage,apnea_data,arousal_data,start_time,params);
    [PLM,~] = periodic_lms(CLM,params);
    [~,ia,~] = intersect(CLM(:,1),PLM(:,1));
    CLM(ia,5) = 1; % go back and mark PLM in CLM
    
    % store output vectors in struct
    plm_outputs.CLM = CLM;
    plm_outputs.PLM = PLM;
    plm_outputs.PLMS = PLM(PLM(:,6) > 0,:);
    plm_outputs.CLMS = CLM(CLM(:,6) > 0,:);
else
    % get CLM from each leg seperately
    %lCLM = separate_candidates(lLM,epochStage,apnea_data,arousal_data,start_time,params);
    %rCLM = separate_candidates(rLM,epochStage,apnea_data,arousal_data,start_time,params);
    
    lCLM = candidate_lms_rev1([],lLM,epochStage,apnea_data,...
        arousal_data,start_time,params);
    rCLM = candidate_lms_rev1(rLM,[],epochStage,apnea_data,...
        arousal_data,start_time,params);
    
    [lPLM,~] = periodic_lms(lCLM,params);
    [~,ia,~] = intersect(lCLM(:,1),lPLM(:,1));
    lCLM(ia,5) = 1; 
    [rPLM,~] = periodic_lms(rCLM,params);
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

plm_outputs.column_headers = {'Start','End','Duration','IMI','isPLM','SleepStage',...
    'Start_in_Min','StartEpoch','Breakpoint','Area','isApnea','isArousal',...
    'Lateraltiynessment'};

end