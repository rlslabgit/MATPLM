function [h, p, means, avgLogIMI] = createIMIGraphsOld()

% Load appropriate directories
[Filename,PathName,~] = uigetfile('*.xlsx'); % prompt for Excel file
[~,~,raw] = xlsread([PathName '/' Filename]); % load Excel file
[Filename,PathName,~] = uigetfile('*.mat'); % prompt for mat file
load([PathName '/' Filename]);
close all

raw(1,:) = [];
raw(46:end,:) = [];
raw = [raw LMdata IMI];
raw = sortcell(raw,[3 5]);
lastPatient = raw{end,3};
means = NaN(str2num(lastPatient(4:end)), 3);
nights = 0;
prev = raw{1,3};
h1 = figure;
h2 = figure;
avgLogIMI = NaN(str2num(lastPatient(4:end)), 3);
for i = 1:size(raw,1);
    patientID = raw{i,3};
    patientNum = str2num(patientID(4:end));

    switch raw{i,5}
        case 'RA'
            raw{i,5} = 1;
        case 'O2'
            raw{i,5} = 2;
        case 'NHF'
            raw{i,5} = 3;
    end
    
    means(patientNum, raw{i,5}) = mean(cell2mat(raw{i,20}(:,4)));
    avgLogIMI(patientNum, raw{i,5}) = mean(raw{i,23});
    raw{i,20} = mean(cell2mat(raw{i,20}(:,4)));
    
    if isnan(raw{i,20})
        means(patientNum, raw{i,5}) = 0;
    end

    if patientID == prev
        nights = nights + 1;
    else
        figure(h1)
        hold on
        plot(cell2mat(raw(i-nights:i-1,5)),cell2mat(raw(i-nights:i-1,20)));
        hold on
        nights = 1;
    end
    
    prev = raw{i,3};
    
    [h, p] = ttest(means(:,1),means(:,2));
    
end

figure(h1)
hold on
scatter(cell2mat(raw(:,5)),cell2mat(raw(:,20)));
xlim([0.5 3.5]);
hold on

end