function [h, p, PLMS5hr] = createPLMSGraphs()

% Load appropriate directories
[Filename,PathName,~] = uigetfile('*.xlsx'); % prompt for Excel file
[~,~,raw] = xlsread([PathName '/' Filename]); % load Excel file
[Filename,PathName,~] = uigetfile('*.mat'); % prompt for mat file
load([PathName '/' Filename]);
close all

raw(1,:) = [];
raw(46:end,:) = [];
raw = [raw LMdata];
raw = sortcell(raw,[3 5]);
lastPatient = raw{end,3};
PLMS5hr = NaN(str2num(lastPatient(4:end)), 3);

nights = 0;
prev = raw{1,3};
figure

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
    
    if patientID == prev
        nights = nights + 1;
    else
        hold on
        plot(cell2mat(raw(i-nights:i-1,5)),cell2mat(raw(i-nights:i-1,9)));
        hold on
        nights = 1;
    end
    
    prev = raw{i,3};
    
    PLMS5hr(patientNum, raw{i,5}) = raw{i,9};
    PLMS5hr(:,1)
    [h, p] = ttest(PLMS5hr(:,1),PLMS5hr(:,2));
    
end

hold on
scatter(cell2mat(raw(:,5)),cell2mat(raw(:,9)));
xlim([0.5 3.5]);
hold on

end