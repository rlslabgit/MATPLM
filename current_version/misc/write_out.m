function out = write_out(plm_outputs,fs,outputpath)
%% out = write_out(plm_outputs,fs,outputpath)
% Writes LM, CLM and PLM data to a text file, which can be imported as
% annotations in an EDF viewer.
%
% inputs:
%   - plm_outputs - struct output by 'matplm_new_main_rev1.m'
%   - fs - sampling rate (hz)
%   - outputpath - the location to save the events file. To prevent the
%   function from writing to a file, assign the empty string '' to this
%   argument.
%
%   OUTPUT FILE FORMAT
%   - 1 header line, with only the labels 'Start' 'Type' & 'Duration' (secs)
%   - tab seperated
%   - 4 types of events: 'right-LM', 'left-LM', 'candidate-LM',
%   'periodic-LM'
%   - Start-time format: 'yyyy-mm-ddTHH:MM:SS.fff'
%   - Duration is reported as fractional seconds

hypnostart = plm_outputs.hypnostart;
rLM = plm_outputs.rLM; rLM(:,3) = (rLM(:,2) - rLM(:,1))/fs;
lLM = plm_outputs.lLM; lLM(:,3) = (lLM(:,2) - lLM(:,1))/fs;
CLM = plm_outputs.CLM(:,1:3);
PLM = plm_outputs.PLM(:,1:3);

t = datestr(rLM(:,1)/fs/3600/24 + datenum(hypnostart),'yyyy-mm-ddTHH:MM:SS.FFF');
rLM = num2cell(rLM); rLM(:,2) = {'right-LM'}; rLM(:,1) = cellstr(t);

t = datestr(lLM(:,1)/fs/3600/24 + datenum(hypnostart),'yyyy-mm-ddTHH:MM:SS.FFF');
lLM = num2cell(lLM); lLM(:,2) = {'left-LM'}; lLM(:,1) = cellstr(t);

t = datestr(CLM(:,1)/fs/3600/24 + datenum(hypnostart),'yyyy-mm-ddTHH:MM:SS.FFF');
CLM = num2cell(CLM(:,1:3)); CLM(:,2) = {'candidate-LM'}; CLM(:,1) = cellstr(t);

t = datestr(PLM(:,1)/fs/3600/24 + datenum(hypnostart),'yyyy-mm-ddTHH:MM:SS.FFF');
PLM = num2cell(PLM(:,1:3)); PLM(:,2) = {'periodic-LM'}; PLM(:,1) = cellstr(t);

ColNames = {'Start' 'Type' 'Duration'};
out = table([rLM(:,1) ; lLM(:,1) ; CLM(:,1) ; PLM(:,1)],...
    [rLM(:,2) ; lLM(:,2) ; CLM(:,2) ; PLM(:,2)],...
    [rLM(:,3) ; lLM(:,3) ; CLM(:,3) ; PLM(:,3)],'VariableNames',ColNames);

if ~isempty(outputpath), writetable(out,outputpath,'delimiter','\t'); end
    