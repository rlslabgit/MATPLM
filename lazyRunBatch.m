%% Load all up-to-date structures and run lazyRun
%  Only saves the bare minimum for now, to make for easy processesing
function lazyRunBatch()
% Load appropriate directories
bigdirname = uigetdir; % prompt for file directory
bigdir = dir([bigdirname '/*PAT*']); % load patient folders
dirlength =  length(bigdir);

% Initialize array for data
data = cell(dirlength,15);
IMI = cell(dirlength,3);
LMdata = cell(dirlength,3);

% Begin loop to read files
for i = 1:dirlength
    % Load the matlab variable
    patientID = bigdir(i).name(6:16);
    load([bigdirname '/' bigdir(i).name '/' patientID '.mat']);

    % Get data from the lazyRun function
    [CLM,PLM5,PLM10,epochStage] = lazyRun(eval(patientID));

    % Add path for axis scaling functions
    addpath('date ticks');
    
    % Graph CLM IMI and durations
    h(1)=figure;
    scatter(CLM(2:end,3), log(CLM(2:end,4)), 'ro');
    xlabel('Duration');
    ylabel('IMI (log scale)');
    yt = get(gca, 'yTick');
    set(gca, 'YTickLabel', round(exp(yt)));
    zoomAdaptiveLogScaleTicks('yon');

    % Create CLMS array and graph
    CLMS=CLM(CLM(2:end,6)>0,:);
    h(2)=figure;
    scatter(CLMS(:,3), log(CLMS(:,4)), 'r*');
    xlabel('Duration');
    ylabel('IMI (log scale)');
    yt = get(gca, 'yTick');
    set(gca, 'YTickLabel', round(exp(yt)));
    zoomAdaptiveLogScaleTicks('yon');

    % Create PLMS10 array and graph
    PLMS10=PLM10(PLM10(2:end,6)>0,:);
    h(3)=figure;
    scatter(PLMS10(:,3), log(PLMS10(:,4)), 'b.');
    xlabel('Duration');
    ylabel('IMI (log scale)');
    yt = get(gca, 'yTick');
    set(gca, 'YTickLabel', round(exp(yt)));
    zoomAdaptiveLogScaleTicks('yon');

    % Create PLMS5 array
    PLMS5=PLM5(PLM5(2:end,6)>0,:);
    
    % Calculate other data
    TST = (30*sum(epochStage>0))/60;
    TRT = (30*size(epochStage,1))/60;
    CLMhr = size(CLM,1)/TRT;
    CLMShr = size(CLMS,1)/TST;
    PLM5hr = size(PLM5,1)/TRT;
    PLMS5hr = size(PLMS5,1)/TST;
    PLM10hr = size(PLM10,1)/TRT;
    PLMS10hr = size(PLMS10,1)/TST;
    
    % Save workspaces, graphs, and data
    % save([bigdirname '/lazyRunWorkspaces/' patientID]);
    savefig(h,[bigdirname '/graphs/' patientID]);
    data(i,1:end) = {patientID size(PLM5,1) PLM5hr size(PLMS5,1) PLMS5hr size(PLM10,1) PLM10hr size(PLMS10,1) PLMS10hr size(CLM,1) CLMhr size(CLMS,1) CLMShr TST TRT};
    IMI(i,1:end) = {PLMS5(:,4) PLMS10(:,4) CLMS(:,4)};
    LMdata(i,1:end) = {PLMS5 PLMS10 CLMS};
    
    % Clear and close all variables and graphs
    clearvars -except bigdir dirlength i bigdirname data IMI LMdata
    close all
    
end % end for loop

% Save data array
save([bigdirname '/lazyRunWorkspaces/data'], 'data', 'IMI', 'LMdata');

end % end function
