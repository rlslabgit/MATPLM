function out = write_out(plm_outputs,fs,outputpath)

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

writetable(out,outputpath,'delimiter','\t');
clear rLM lLM CLM PLM ColNames t hypnostart