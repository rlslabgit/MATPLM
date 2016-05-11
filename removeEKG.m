function [EKGless, peaks] = removeEKG(dsEMG,dsEKG,fs)
%% Subtracts EKG from noisey EMG channels
% [EKGless, peaks] = removeEKG(dsEMG,dsEKG,fs)
%
%   inputs:
%       dsEMG - filtered, rectified EMG channel (truncated to sleep study)
%       dsEKG - optionally filtered (truncated to sleep study)
%       fs - sampling rate

%   outputs:
%       EKGless - EMG channel without EKG interference (bold?)
%       peaks - loc and amp of r-wave peaks


EKGless = dsEMG(:,1);
r_point = 20000; % attempt at finding r wave

% Mark where EKG passes above some threshold (want to avoid s wave)
r_edges = (dsEKG(:,1).^2 > r_point);

% Copy all points above r_point. Mark breakpoints, i.e. points separated by
% more than one point (nonconsecutive -> different waves)
beats = find(r_edges > 0);
beats(2:end,2) = abs(beats(1:end-1,1)-beats(2:end,1)) > 1;
beats(1,2) = 1;

% Transform into an array with start and stop times for each beat
a = find(beats(:,2) == 1);
a(:,2) = beats(a(:,1),1);
a(1:end-1,3) = beats(a(2:end,1)-1,1);
a(end,3) = beats(end,1);

%%
peaks = zeros(size(a,1)-2,3);

frontbuff = round(fs/10);
backbuff = round(fs/10);

% ignore first and last, causes too many problems
for i = 2:size(a,1)-1
    
    [~,mid] = max(dsEKG(a(i,2):a(i,3),1));
    mid = a(i,2) + mid;
    
    % Bound safety check (should never be false)
    if mid-2*frontbuff > 0
         EKGless(mid-frontbuff:mid) = dsEMG(mid-2*frontbuff:mid-frontbuff);
    end
    if mid+2*backbuff <= size(EKGless,1)
        EKGless(mid:mid+backbuff) = dsEMG(mid+backbuff:mid+2*backbuff);
    end
    
%     peaks(i-1,1) = mid; % location of peak
%     peaks(i-1,2) = dsEKG(mid,1); % remember: EKG is squared
%     peaks(i-1,3) = dsEMG(mid,1) > mean(dsEMG(mid-2*frontbuff:mid-frontbuff,1))...
%         + 5 * std(dsEMG(mid-2*frontbuff:mid-frontbuff,1));
end

end