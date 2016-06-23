function [kEMG, did] = removeEKG_rev1(EMG,fs,t)
%% [kEMG, did] = removeEKG_rev1(EMG,fs,t)
% Remove EKG intereference from EMG signal by averaging out peaks when
% intereference is detected
% 
% inputs:
%   - EMG - 1 x n filtered, rectified EMG signal
%   - fs - sampling rate (hz)
%   - t - 1 x n array representing baseline noise (output from 'dt.m')
%
% outpus:
%   - kEMG - EMG with EKG peaks smoothed out
%   - did - boolean of whether any changes were made to original signal


kEMG = EMG; did = false;
% turn off peak warning, it just means there are no peaks in this epoch
warning('off','signal:findpeaks:largeMinPeakHeight')
window_size = fs * 30;  % try a 30 second sliding window

% check 30 second segments for EKG interference. We could probably increase
% this even more, because it is actually pretty safe, so there's not too
% much of a penalty for overreacclearting
for n = 0:(floor(size(EMG,1)/window_size)-1)
    cur_start = n*window_size+1; cur_end = (n+1)*window_size;
    interest = EMG(cur_start:cur_end,1);        
    
    hit = t(cur_start);
    [~, rel] = findpeaks(interest.^2,'MinPeakHeight',hit.^2,...
        'MinPeakDistance',0.150*fs);
    rel(2:end,2) = (rel(2:end,1) - rel(1:end-1,1))/fs;
    beats = rel(:,2) > 0.7 & rel(:,2) < 1.3;
    
    if size(rel,1) > 20 && sum(beats)/size(rel,1) > 0.2
        did = true;
        kEMG(cur_start:cur_end,1) = kill_peaks(interest,rel,fs);
    end
end
warning('on','signal:findpeaks:largeMinPeakHeight')
end


function cleaned = kill_peaks(EMG,beats,fs)
%% cleaned = kill_peaks(EMG,beats,fs)
% At the location of likely EKG interference, average out the surrounding
% 0.2 seconds.

frontbuff = round(fs/10);
backbuff = round(fs/10);

cleaned = EMG;

for i = 1:size(beats,1)
    
    % Bound safety check (should never be false)
    if beats(i)-2*frontbuff > 0
         cleaned(beats(i)-frontbuff:beats(i)) = ...
             EMG(beats(i)-2*frontbuff:beats(i)-frontbuff);
    end
    if beats(i)+2*backbuff <= size(cleaned,1)
        cleaned(beats(i):beats(i)+backbuff)...
            = EMG(beats(i)+backbuff:beats(i)+2*backbuff);
    end
    
end
end