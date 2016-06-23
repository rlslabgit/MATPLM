function subj_struct = convert_1sub_rev1(varargin)
%% EDF = convert_1sub()
% convert EDF and event data to struct for PLM processing. 
%
% optional input:
%   - filepath to subject folder containing edf and event text files.

addpath(['C:\Users\Administrator\Documents\GitHub\MATPLM (rlslabgit)\'...
    'EDF Conversion']);

home = pwd;

new_format = 'yyyy-mm-dd HH:MM:SS.fff'; % outputted date format

if nargin == 1
    path = varargin{1}; cd(path)
    s = dir('*SleepStage*'); s = empty_struct(s);
    r = dir('*Arousal*'); r = empty_struct(r);
    p = dir('*Apnea*'); p = empty_struct(p);
    edf = dir('*.edf'); edf = empty_struct(edf);
else
    edf = ''; s = ''; r = ''; p = '';
end

[havs, canc, date_format] = what_have(edf,s,r,p);

if canc, return; end
if isempty(havs.file_loc), return; end
fd_format = date_format; % date format in the txt files

subj_struct = EDF_read_jhmi_rev_101(havs.file_loc);
%EDF = struct([]);
subj_struct.EDFStart = subj_struct.dateTime;

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
    
    subj_struct.CISRE_Hypnogram = a;
    subj_struct.EDFStart2HypnoInSec = etime(datevec(subj_struct.CISRE_HypnogramStart),...
        datevec(subj_struct.EDFStart));
end

if ~isempty(havs.ar_loc) && havs.ar
    % Hypnogram filename should contain the word 'SleepStage'
    T = readtable(havs.ar_loc,'headerlines',havs.ar_head,'Delimiter','\t');
    T = table2cell(T);
    if size(T,1) > 0
        T(:,1) = cellstr(datestr(datenum(T(:,1),fd_format),new_format));  
        subj_struct.CISRE_Arousal = T;
    else
        subj_struct.CISRE_Arousal = cell(0);
    end
else
    subj_struct.CISRE_Arousal = cell(0);
end

if ~isempty(havs.ap_loc) && havs.ap
% Apnea filename should contain the word 'Apnea'
    T = readtable(havs.ap_loc,'headerlines',havs.ap_head,'Delimiter','\t');
    T = table2cell(T);
    if size(T,1) > 0
        T(:,1) = cellstr(datestr(datenum(T(:,1),fd_format),new_format));  
        subj_struct.CISRE_Apnea = T;
    else
        subj_struct.CISRE_Apnea = cell(0);
    end
else
    subj_struct.CISRE_Apnea = cell(0);
end


cd(home)
end


function [Answer, Cancelled, date_format] = what_have(edf,s,r,p)
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
DefAns(1).hyp = true;

Prompt(end+1,:) = {'Headerlines' 'hyp_head', []};
Formats(1,2).type = 'edit'; Formats(1,2).format = 'integer';
Formats(1,2).size = 50;
DefAns.hyp_head = 14;

Prompt(end+1,:) = {'Apnea Data' 'ap',[]};
Formats(2,1).type = 'check';
DefAns.ap = true;

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
DefAns.ar = true;

Prompt(end+1,:) = {'Headerlines' 'ar_head', []};
Formats(3,2).type = 'edit'; Formats(3,2).format = 'integer';
Formats(3,2).size = 50;
DefAns.ar_head = 18;

Prompt(end+1,:) = {'EDF path', 'file_loc', []};
Formats(5,1).type = 'edit'; Formats(5,1).format = 'file';
Formats(5,1).limits = [0 1]; % use uiputfile
Formats(5,1).span = [1, 3];  % item is 1 field x 3 fields
Formats(5,1).items = {'*.edf','European Data Format';'*.*','All Files'};
DefAns.file_loc = edf;

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

end

function a = empty_struct(b)
    if size(b,1) > 0, a = b(1).name;
    else a = ''; end
end