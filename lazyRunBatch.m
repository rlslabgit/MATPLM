% Load all up-to-date structures and run lazyRun
% Only saves the bare minimum for now, to make for easy processesing
function lazyRunBatch()
bigdirname = uigetdir; % prompt for file directory
bigdir = dir([bigdirname '/*PAT*']); % load patient folders
dirlength =  length(bigdir);

for i = 1:dirlength
    
    % Load the matlab variable
    patientID = bigdir(i).name(6:16);
    load([bigdirname '/' bigdir(i).name '/' patientID '.mat']);
    
    [CLM,PLM5,PLM10,epochStage] = lazyRun(eval(patientID));
    
    add date ticks;
    
    figure
    scatter(CLM(2:end,3), log(CLM(2:end,4)), 'ro');
    xlabel('Duration');
    ylabel('IMI (log scale)');
    yt = get(gca, 'yTick');
    set(gca, 'YTickLabel', round(exp(yt)));
    zoomAdaptiveLogScaleTicks('yon');
    
    TST = (30*sum(epochStage))/60;
    PLM5hr = size(PLM5)/TST;
    PLM10hr = size(PLM10)/TST;
    
    save([bigdirname '/batch/' patientID]);
    savefig([bigdirname '/graphs/' patientID]);
    
    clearvars -except bigdir dirlength i bigdirname
    close all
    
end % end for loop
end % end function