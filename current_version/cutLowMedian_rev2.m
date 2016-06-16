function nLM = cutLowMedian_rev2(LM,EMG,fs,t)
%% nLM = cutLowMedian_rev1(LM,EMG,fs,t)
% Extract leg movements which pass minimum morphology criterion, defined
% presently as a 0.5 second window with median amplitude above low
% threshold
%
% inputs:
%   - LM - monolateral LM array with start and stop times of each movement
%   - EMG - EMG signal corresponding to the leg LM was derived from
%   - fs - sampling rate (hz)
%   - t - vector of low threshold values. Second column of vector output
%   from 'dt.m'.
%
% CURRENT VERSION AS OF JUNE 16

nLM = LM * 0; j = 1;
meds = medfilt1(EMG, fs/2+1);

for i = 1:size(LM,1)
    d = [];
    d(:,1) = meds(LM(i,1):LM(i,2));
    d(:,2) = t(LM(i,1):LM(i,2),2);
    if sum(d(:,1) > d(:,2)) > 0
        nLM(j,:) = LM(i,:);
        j = j+1;
    end
end

nLM = nLM(1:j-1,:);