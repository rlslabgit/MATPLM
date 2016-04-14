function [hypnogram_start,simp_hyp] = brainRT_to_hypnogram(all_events)

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
end