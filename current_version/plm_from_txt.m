function [lm_tbl,PLM] = plm_from_txt(varargin)
%% [PLMS,PLM] = plm_from_txt(filename,varargin)
% This function reads in a text file containing manually (or otherwise
% externally) scored leg movements.
%
% inputs (all optional, window will appear):
%   - lm_file - file containing start time, event type, and duration
%   - epochstage - hypnogram file, right now expects 30 second epochs with
%   1 line per epoch
%   - t_type_dur - solumn numbers for start time, event type and
%   duration. Default is [1,2,3]
%   - datef - format of dates in event files. Default is yyyy-mm-ddTHH:MM:SS.fff
%   - arousal - file containing arousal events, same column order as
%   lm_file and epoch stage
%   - apnea - apnea and respiratory events file. Same deal...
%
% TODO: support different event types - right now we don't care as long as
% it is in the LM txt file - specifically, allow left/right

% testing path
% 'D:\Glutamate Study\AidRLS, G00583_V1N1 - 5_15_2013\G00583_V1N1 AidRLS-Events PLM.txt'

p = inputParser;
p.CaseSensitive = false;

p.addParameter('lm_file','',@exist)
p.addParameter('epochstage','',@exist)

% locations of the start time (t) in some parseable date format, type of
% the event and duration in seconds
p.addParameter('t_type_dur',[1,2,3],@(x) size(x,2) == 3);

% date format of the 'start' column of the input file. No check on this, so
% be careful I guess
p.addParameter('datef','yyyy-mm-ddTHH:MM:SS.fff')

p.addParameter('arousal','',@exist);
p.addParameter('apnea','',@exist);

p.parse(varargin{:})

new_format = 'yyyy-mm-dd HH:MM:SS.fff'; % format the program likes

% if p.Results.headerlines < 0, lm_tbl = readtable(p.Results.filename);
% else lm_tbl = readtable(p.Results.filename,'headerlines',p.Results.headerlines); end

PLM = [];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
lm_file = p.Results.lm_file;
s = p.Results.epochstage; 
r = p.Results.arousal; 
ap = p.Results.apnea;
[havs, canc, date_format] = what_have(lm_file,s,r,ap);

if canc, return; end

lm_tbl = readtable(havs.file_loc);

fd_format = date_format; % date format in the txt files

ep = zeros(960,1);
if ~isempty(havs.hyp_loc) && havs.hyp
    % Hypnogram filename should contain the word 'SleepStage'
    T = readtable(havs.hyp_loc,'headerlines',havs.hyp_head,'Delimiter','\t');
    
    d = char(T.Var1(1)); 
    subj_struct(1).CISRE_HypnogramStart = datestr(datenum(d,fd_format),new_format);
    T = T.Var2;
    
    a = zeros(size(T,1),1);
    a(~cellfun('isempty', strfind(T,'1'))) = 1;
    a(~cellfun('isempty', strfind(T,'2'))) = 2;
    a(~cellfun('isempty', strfind(T,'3'))) = 3;
    a(~cellfun('isempty', strfind(T,'4'))) = 4;
    a(~cellfun('isempty', strfind(T,'REM'))) = 5;
    
    ep = a;
    clear T a
end

arousals = cell(0);
if ~isempty(havs.ar_loc) && havs.ar
    % Hypnogram filename should contain the word 'SleepStage'
    T = readtable(havs.ar_loc,'headerlines',havs.ar_head,'Delimiter','\t');
    T = table2cell(T);
    if size(T,1) > 0
        T(:,1) = cellstr(datestr(datenum(T(:,1),fd_format),new_format));  
        arousals = T;
        clear T
    end
end

apneas = cell(0);
if ~isempty(havs.ap_loc) && havs.ap
% Apnea filename should contain the word 'Apnea'
    T = readtable(havs.ap_loc,'headerlines',havs.ap_head,'Delimiter','\t');
    T = table2cell(T);
    if size(T,1) > 0
        T(:,1) = cellstr(datestr(datenum(T(:,1),fd_format),new_format));  
        apneas = T;
        clear T
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

LM = zeros(size(lm_tbl,1),2);

% arbitrary start time 60 seconds prior to the first movement. We'll go
% back and replace actual times later
tmp_start = datenum(lm_tbl{1,1},p.Results.datef) - 60/86400;


% just arbitrarily make it 500 hz... it doesn't matter, but it's easier to
% manipulate the date input than to rewrite my scoring code
LM(:,1) = datenum(lm_tbl{:,1},p.Results.datef);
LM(:,1) = round((LM(:,1) - tmp_start) * 86400 * 500);
lm_tbl.pointid = LM(:,1); % know which point we used
LM(:,2) = LM(:,1) + 500 * lm_tbl{:,3};

% TODO: make left/right explicit

% this is a toolbox function, I should add this to the repo at some point
% but I like having one global version
LM = remove_overlap(LM,500,0.5);

params = getInput2(500,1);


CLM = candidate_lms(LM,[],ep,params,apneas,arousals);
x = periodic_lms(CLM,params);

plm_results = struct();
plm_results.PLM = x;
plm_results.PLMS = x(x(:,6) > 0,:);
plm_results.CLM = CLM;
plm_results.CLMS = CLM(CLM(:,6) > 0,:);
plm_results.epochstage = ep;

% put this all into a table for easier access
P = array2table(x(:,[1:4,6,8:9]));


x = innerjoin(P,lm_tbl,'leftkeys',1,'rightkeys','pointid',...
    'rightvariables',[p.Results.t_type_dur(1),p.Results.t_type_dur(3)]);

starts = datetime(datevec(x{:,8},p.Results.datef),...
    'format','yyyy-MM-dd hh:mm:ss.SSS');
stops = starts(:,1) + seconds(x{:,9});

PLM = table(starts,stops,x{:,3},x{:,4},x{:,5},x{:,6},x{:,7});
PLM.Properties.VariableNames = {'start','stop','duration','imi',...
    'sleepstage','epoch','breakpoint'};

generate_report(plm_results, params);
end

function [Answer, Cancelled, date_format] = what_have(lm_file,s,r,p)
%%%% SETTING DIALOG OPTIONS
Options.Resize = 'on';
Options.Interpreter = 'tex';
Options.CancelButton = 'on';
Option.Dim = 3; % Horizontal dimension in fields

Prompt = {};
Formats = {};
DefAns = struct([]);

Title = 'What data you got?';

Prompt(1,:) = {'Hypnogram' 'hyp',[]};
Formats(1,1).type = 'check';
DefAns(1).hyp = false;

Prompt(end+1,:) = {'Headerlines' 'hyp_head', []};
Formats(1,2).type = 'edit'; Formats(1,2).format = 'integer';
Formats(1,2).size = 50;
DefAns.hyp_head = 14;

Prompt(end+1,:) = {'Apnea Data' 'ap',[]};
Formats(2,1).type = 'check';
DefAns.ap = false;

Prompt(end+1,:) = {'Headerlines' 'ap_head', []};
Formats(2,2).type = 'edit'; Formats(2,2).format = 'integer';
Formats(2,2).size = 50;
DefAns.ap_head = 20;

Prompt(end+1,:) = {'Date Format' 'file_date', []};
Formats(2,3).type = 'list'; Formats(2,3).style = 'popupmenu';
Formats(2,3).items = {'yyyy-mm-ddTHH:MM:SS.fff', 'yyyy-mm-dd HH:MM:SS.fff'...
    'yyyy-mm-ddTHH:MM:SS', 'yyyy-mm-dd HH:MM:SS'};

Prompt(end+1,:) = {'Arousal Data' 'ar',[]};
Formats(3,1).type = 'check';
DefAns.ar = false;

Prompt(end+1,:) = {'Headerlines' 'ar_head', []};
Formats(3,2).type = 'edit'; Formats(3,2).format = 'integer';
Formats(3,2).size = 50;
DefAns.ar_head = 18;

Prompt(end+1,:) = {'LM file path', 'file_loc', []};
Formats(5,1).type = 'edit'; Formats(5,1).format = 'file';
Formats(5,1).limits = [0 1]; % use uiputfile
Formats(5,1).span = [1, 3];  % item is 1 field x 3 fields
Formats(5,1).items = {'*.txt','Text Files';'*.*','All Files'};
DefAns.file_loc = lm_file;

Prompt(end+1,:) = {'Hypnogram path', 'hyp_loc', []};
Formats(6,1).type = 'edit'; Formats(6,1).format = 'file';
Formats(6,1).limits = [0 1]; % use uiputfile
Formats(6,1).span = [1, 3];  % item is 1 field x 3 fields
Formats(6,1).items = {'*.txt','Text Files';'*.*','All Files'};
DefAns.hyp_loc = s;

Prompt(end+1,:) = {'Arousal path', 'ar_loc', []};
Formats(7,1).type = 'edit'; Formats(7,1).format = 'file';
Formats(7,1).limits = [0 1]; % use uiputfile
Formats(7,1).span = [1, 3];  % item is 1 field x 3 fields
Formats(7,1).items = {'*.txt','Text Files';'*.*','All Files'};
DefAns.ar_loc = r;

Prompt(end+1,:) = {'Apnea path', 'ap_loc', []};
Formats(8,1).type = 'edit'; Formats(8,1).format = 'file';
Formats(8,1).limits = [0 1]; % use uiputfile
Formats(8,1).span = [1, 3];  % item is 1 field x 3 fields
Formats(8,1).items = {'*.txt','Text Files';'*.*','All Files'};
DefAns.ap_loc = p;

[Answer,Cancelled] = inputsdlg(Prompt,Title,Formats,DefAns,Options);
date_format = Formats(2,3).items{Answer.file_date};

if isempty(Answer.file_loc), Cancelled = true; end

% TODO: is this really the best thing to do for no hypnogram?
if isempty(Answer.hyp_loc)
   warning('Hypnogram file is highly recommended, all PLM will be regarded as wake'); 
end

if isempty(Answer.ar_loc)
    warning('Arousal event file is recommended, no PLM-arousal associations will be reported');
end

if isempty(Answer.ap_loc)
    warning('Respiratory event file is recommended, no PLM-respiratory associations will be reported');
end


end