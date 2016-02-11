function createGraphs()

% Load appropriate directories
dirname = uigetdir; % prompt for file directory
[Filename,PathName,~] = uigetfile('*.xlsx'); % prompt for Excel file
[~,~,raw] = xlsread([PathName '/' Filename]); % load Excel file
directory = dir([dirname '/*.fig']); % load figure directory
dirlength =  length(directory);

close all force
h1 = figure;
pos = get(gcf,'OuterPosition');
pos(3:4) = [900 2000];
set(gcf,'OuterPosition',pos);

for i = 1:dirlength
    patientID = directory(i).name(1:11);
    row = str2num(patientID(4:6));
    switch raw{(i+1),6}
        case 'RA'
            col = 1;
        case 'O2'
            col = 2;
        case 'NHF'
            col = 3;
    end
    h2 = openfig([dirname '/' patientID '.fig'], 'reuse', 'invisible');
    zoomAdaptiveLogScaleTicks('yon');
    zoomAdaptiveLogScaleTicks('yoff');
    figure(h2(3));
    zoomAdaptiveLogScaleTicks('yon');
    zoomAdaptiveLogScaleTicks('yoff');
    ax1 = gca;
    zoomAdaptiveLogScaleTicks('yon');
    zoomAdaptiveLogScaleTicks('yoff');

    figure(h1);
    s = subplot(5,3,(3*(row-1)+col));
    fig = get(ax1, 'children');
    copyobj(fig,s,'legacy');
    zoomAdaptiveLogScaleTicks('yon');
    zoomAdaptiveLogScaleTicks('yoff');

    clearvars -except dirname Filename PathName raw directory dirlength i h1
    figs = get(0,'children');
    figs(figs == gcf) = []; % delete current figure from the list
    close(figs, 'hidden');
end

clearvars

end