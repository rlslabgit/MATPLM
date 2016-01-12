% Load all up-to-date structures and run fullRunComboScript
% Only saves the bare minimum for now, to make for easy processesing
function BatchProcess()

bigdir = dir('Y:\AidRLS*V1N2*'); % Just night 2 for now...
dirlength =  length(bigdir);

for i = 1:dirlength
    
    % Load the matlab variable
    patientID = bigdir(i).name(9:19);
    load(['Y:\' bigdir(i).name '\' patientID '.mat']);
    
    [CLM,nCLM,CLMt,nCLMt,PLMt,nPLMt] = lazyRun(eval(patientID)); %#ok<ASGLU>
    
    save(['C:\Users\Administrator\Documents\MedianTestWorkspaces\' patientID],'*LM*');
    
    clearvars -except bigdir dirlength i
end % end for loop
end % end function