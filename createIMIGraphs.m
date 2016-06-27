function [h_avg, p_avg, h_med, p_med, h_avg_start, p_avg_start,...
    h_med_start, p_med_start, h_avg_end, p_avg_end, h_med_end, p_med_end,...
    avgLogIMI, stdLogIMI, medLogIMI, avgLogIMIstart, medLogIMIstart,...
    stdLogIMIstart, avgLogIMIend, medLogIMIend, stdLogIMIend, raw,...
    individualTTests] = createIMIGraphs()

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
avgLogIMI = NaN(str2num(lastPatient(4:end)), 3);
stdLogIMI = NaN(str2num(lastPatient(4:end)), 3);
medLogIMI = NaN(str2num(lastPatient(4:end)), 3);

avgLogIMIstart = NaN(str2num(lastPatient(4:end)), 3);
stdLogIMIstart = NaN(str2num(lastPatient(4:end)), 3);
medLogIMIstart = NaN(str2num(lastPatient(4:end)), 3);

avgLogIMIend = NaN(str2num(lastPatient(4:end)), 3);
stdLogIMIend = NaN(str2num(lastPatient(4:end)), 3);
medLogIMIend = NaN(str2num(lastPatient(4:end)), 3);

individualNightIMIs = cell(str2num(lastPatient(4:end)), 3);

nights = 0;
prev = raw{1,3};
h1=figure;
h2=figure;
h3=figure;
h4=figure;
f=1;

for i = 1:size(raw,1);
    patientID = raw{i,3};
    patientNum = str2num(patientID(4:end));
    TRT = raw{i,19};

    switch raw{i,5}
        case 'RA'
            raw{i,5} = 1;
        case 'O2'
            raw{i,5} = 2;
        case 'NHF'
            raw{i,5} = 3;
    end
    
    avgLogIMI(patientNum, raw{i,5}) = mean(log(raw{i,23}(raw{i,23}<90)));
    stdLogIMI(patientNum, raw{i,5}) = std(log(raw{i,23}(raw{i,23}<90)));
    medLogIMI(patientNum, raw{i,5}) = median(log(raw{i,23}(raw{i,23}<90)));
    
    avgLogIMIstart(patientNum, raw{i,5}) = mean(log(raw{i,23}(raw{i,20}(:,4)<90 & raw{i,20}(:,2)<(3*3600*500))));
    stdLogIMIstart(patientNum, raw{i,5}) = std(log(raw{i,23}(raw{i,20}(:,4)<90 & raw{i,20}(:,2)<(3*3600*500))));
    medLogIMIstart(patientNum, raw{i,5}) = median(log(raw{i,23}(raw{i,20}(:,4)<90 & raw{i,20}(:,2)<(3*3600*500))));
 
    avgLogIMIend(patientNum, raw{i,5}) = mean(log(raw{i,23}(raw{i,20}(:,4)<90 & raw{i,20}(:,2)>(TRT*60*500-(3*3600*500)))));
    stdLogIMIend(patientNum, raw{i,5}) = std(log(raw{i,23}(raw{i,20}(:,4)<90 & raw{i,20}(:,2)>(TRT*60*500-(3*3600*500)))));
    medLogIMIend(patientNum, raw{i,5}) = median(log(raw{i,23}(raw{i,20}(:,4)<90 & raw{i,20}(:,2)>(TRT*60*500-(3*3600*500)))));
 
    raw{i,26} = mean(log(raw{i,23}(raw{i,23}<90)));
    raw{i,28} = mean(log(raw{i,23}(raw{i,23}<90 & raw{i,9}>10)));
    
    individualNightIMIs{patientNum, raw{i,5}} = raw{i,23}
    
    if raw{i,9} > 10
        raw{i,27} = NaN;
    else
        raw{i,27} = raw{i,9};
    end
    
    if patientID == prev
        nights = nights + 1;
    else
        figure(h1)
        hold on
        plot(cell2mat(raw(i-nights:i-1,5)),cell2mat(raw(i-nights:i-1,9)));
%         colorOrder = get(gca, 'ColorOrder')
        figure(h2)
        hold on
        plot(cell2mat(raw(i-nights:i-1,5)),cell2mat(raw(i-nights:i-1,28)));
        figure(h3)
        hold on
        plot(cell2mat(raw(i-nights:i-1,5)),cell2mat(raw(i-nights:i-1,26)));
        figure(h4)
        hold on
        plot(cell2mat(raw(i-nights:i-1,5)),cell2mat(raw(i-nights:i-1,27)));
        nights = 1;
        f = f + 1;
    end
    
    prev = raw{i,3};
    
    [h_avg, p_avg] = ttest(avgLogIMI(:,1),avgLogIMI(:,2));
    [h_med, p_med] = ttest(medLogIMI(:,1),medLogIMI(:,2));
    
    [h_avg_start, p_avg_start] = ttest(avgLogIMIstart(:,1),avgLogIMIstart(:,2));
    [h_med_start, p_med_start] = ttest(medLogIMIstart(:,1),medLogIMIstart(:,2));

    [h_avg_end, p_avg_end] = ttest(avgLogIMIend(:,1),avgLogIMIend(:,2));
    [h_med_end, p_med_end] = ttest(medLogIMIend(:,1),medLogIMIend(:,2));

end

individualTTests = NaN(str2num(lastPatient(4:end)), 2);
for i=1:size(individualNightIMIs,1)
    if size(individualNightIMIs{i,1},1) > 0 && size(individualNightIMIs{i,2},1) > 0
        [h, p] = ttest2(individualNightIMIs{i,1}, individualNightIMIs{i,2});
        individualTTests(i,:) = [h p];
    end
end

figure(h1)
hold on
scatter(cell2mat(raw(:,5)),cell2mat(raw(:,9)));
xlim([0.5 3.5]);

end