function [EDF_sup] = brainRT_prep(all_events)
%% [EDF_sup] = brainRT_prep(all_events)
[EDF_sup] = EDF_read_jhmi_rev_101(); % open window to pick file

% trim off all the unneeded channels so it doesn't take 10 mins to load
i = 1;

while i <= size(EDF_sup.Signals,2)
    if ~findWanted(EDF_sup.Signals(i).label)
        EDF_sup.Signals(:,i) = [];
    else
        i = i + 1;
    end    
end

lbls = extractfield(EDF_sup.Signals,'label');
idx = find(not(cellfun('isempty', strfind(lbls,'JbG'))));
EDF_sup.Signals(idx).label = 'Left Leg';
idx = find(not(cellfun('isempty', strfind(lbls,'JbD'))));
EDF_sup.Signals(idx).label = 'Right Leg';
idx = find(not(cellfun('isempty', strfind(lbls,'ECG'))));
EDF_sup.Signals(idx).label = 'EKG';

codes = cell2mat(all_events(:,1)); % extract event codes
hypnogram = all_events(codes == 128,[2,4,5]); % 128 is code for hypnogram
hypnogram_start = hypnogram{1,2};

% convert to our sleep stage format
stage_codes = cell2mat(hypnogram(:,1));
hypnogram(stage_codes == 2, 1) = {0};
hypnogram(stage_codes == 301, 1) = {1};
hypnogram(stage_codes == 302, 1) = {2};
hypnogram(stage_codes == 303, 1) = {3};
hypnogram(stage_codes == 304, 1) = {4};
hypnogram(stage_codes == 201, 1) = {5};

% date format in the xml file
formatIn = 'yy-mm-ddTHH:MM:SS';
for i = 1:size(hypnogram,1)
    N1 = datevec(char(hypnogram{i,2}),formatIn); % start time
    N2 = datevec(char(hypnogram{i,3}),formatIn); % end time
    hypnogram{i,3} = etime(N2,N1); % replace end time with duration in secs
end

% now make our simple hypnogram file
simp_hyp = [];
for i = 1:size(hypnogram,1)
    for j = 1:(hypnogram{i,3}/30)
        simp_hyp = [simp_hyp ; hypnogram{i,1}];
    end
end

EDF_sup.CISRE_HypnogramStart = hypnogram_start;
EDF_sup.CISRE_Hypnogram = simp_hyp;

% Now we add things like times
EDF_sup.EDFStart = ['20' EDF_sup.date(7:8) '-' EDF_sup.date(4:5) '-'...
    EDF_sup.date(1:2) ' ' EDF_sup.time(1:2) ':' EDF_sup.time(4:5) ':'...
    EDF_sup.time(7:8)];

% Time between start of recording and start of scoring
EDF_DTvec = datenum(EDF_sup.EDFStart); % fine, its default form
Hypno_DTvec = datenum(hypnogram_start,'yyyy-mm-ddTHH:MM:SS');
EDF_sup.EDFStart2HypnoInSec = etime(datevec(EDF_DTvec),datevec(Hypno_DTvec));

% TODO: Apnea and Arousal from events file?
EDF_sup.CISRE_Apnea = num2cell(zeros(1,3));
EDF_sup.CISRE_Arousal = num2cell(zeros(1,3));


end

function [wanted] = findWanted(sig_name)

l = strfind(sig_name,'JbG');
r = strfind(sig_name, 'JbD');
c = strfind(sig_name, 'ECG');

if ~isempty(l) || ~isempty(r) || ~isempty(c)
    wanted = true;
else
    wanted = false;
end

end