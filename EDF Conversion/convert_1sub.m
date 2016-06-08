function EDF = convert_1sub()
%% EDF = convert_1sub(FilePath)

addpath(['C:\Users\Administrator\Documents\GitHub\MATPLM (rlslabgit)\'...
    'current_version']);
addpath(['C:\Users\Administrator\Documents\GitHub\MATPLM (rlslabgit)\'...
    'EDF Conversion']);

new_format = 'yyyy-mm-dd HH:MM:SS.fff'; % outputted date format

[havs, canc, date_format] = what_have();
if canc, return; end
fd_format = date_format; % date format in the txt files

cd(havs.file_loc);

edf = dir('*.edf'); edf = edf(1).name;
EDF = EDF_read_jhmi_rev_101(edf);
%EDF = struct([]);
EDF.EDFStart = EDF.dateTime;

if havs.hyp
    % Hypnogram filename should contain the word 'SleepStage'
    f = dir('*SleepStage*'); f = f(1).name;
    T = readtable(f,'headerlines',14);
    
    d = char(T.Var1(1)); 
    EDF(1).CISRE_HypnogramStart = datestr(datenum(d,fd_format),new_format);
    T = T.Var2;
    
    a = zeros(size(T,1),1);
    a(~cellfun('isempty', strfind(T,'1'))) = 1;
    a(~cellfun('isempty', strfind(T,'2'))) = 2;
    a(~cellfun('isempty', strfind(T,'3'))) = 3;
    a(~cellfun('isempty', strfind(T,'4'))) = 4;
    a(~cellfun('isempty', strfind(T,'REM'))) = 5;
    
    EDF.CISRE_Hypnogram = a;
    EDF.EDFStart2HypnoInSec = etime(datevec(EDF.CISRE_HypnogramStart),...
        datevec(EDF.EDFStart));
end

if havs.ar
    % Hypnogram filename should contain the word 'SleepStage'
    f = dir('*Arousal*'); f = f(1).name;
    T = readtable(f,'headerlines',18);
    T = table2cell(T);
    if size(T,1) > 0
        T(:,1) = cellstr(datestr(datenum(T(:,1),fd_format),new_format));  
        EDF.CISRE_Arousal = T;
    else
        EDF.CISRE_Arousal = cell(0);
    end
end

if havs.ap
% Apnea filename should contain the word 'Apnea'
    f = dir('*Apnea*'); f = f(1).name;
    T = readtable(f,'headerlines',20);
    T = table2cell(T);
    if size(T,1) > 0
        T(:,1) = cellstr(datestr(datenum(T(:,1),fd_format),new_format));  
        EDF.CISRE_Apnea = T;
    else
        EDF.CISRE_Apnea = cell(0);
    end
end



end


function [Answer, Cancelled, date_format] = what_have()
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

Prompt(end+1,:) = {'File Location', 'file_loc', []};
Formats(5,1).type = 'edit'; Formats(5,1).format = 'dir';
Formats(5,1).limits = [1 0]; % use uiputfile
Formats(5,1).span = [1, 3];  % item is 1 field x 3 fields
d = dir;
files = strcat([pwd filesep],{d(~[d.isdir]).name});
DefAns.file_loc = pwd;



[Answer,Cancelled] = inputsdlg(Prompt,Title,Formats,DefAns,Options);
date_format = Formats(2,3).items{Answer.file_date};

end