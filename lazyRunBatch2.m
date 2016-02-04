%% Load all up-to-date structures and run lazyRun
%  Only saves the bare minimum for now, to make for easy processesing
function lazyRunBatch2()
% Load appropriate directories
dirName = uigetdir; % prompt for file directory
directory = dir([dirName]); % load patient folders
dirlength =  length(directory);

% Begin loop to read files
for i = 1:dirlength
    % Load the matlab variable
    patientID = directory(i).name(1:11);
    load([dirName '/' patientID '.mat']);

    