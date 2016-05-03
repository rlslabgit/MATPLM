function [ndsEMG,threshes,minT,badEps] = dynamicThresholdX(dsEMG,fs)
%% Normalize dsEMG signal to a common baseline
% [dsEMG,threshes] = dynamicThreshold2(dsEMG,fs);
%
% dynamicThreshold2 is an attempt at normalizing the dsEMG vector to a
% baseline noise level of 2 \mu v. It loops through epochs of size
% bigWindow and finds all points that are below 5 standard deviations above
% the mean of the surrounding littleWindow # of points. The threshold for
% which the most values lie below that value is regarded as the baseline,
% and the bigWindow is normalized using the factor minT/baseline.
%
% Inputs:
%   dsEMG - filtered and rectified EMG signal
%   fs - sampling rate
%
% Outputs:
%   dsEMG - normalized dsEMG signal
%   threshes - thresholds calculated at each bigWindow
%   minT - value the signal is normalized to.

addpath('helper_functions')


bigWindow = 15*fs; littleWindow = round((0.1)*fs)+1;

threshes = zeros(floor(size(dsEMG,1)/bigWindow),1);
badEps = []; % epoch numbers (in bigWindow epochs) of noisey signal
ndsEMG = dsEMG * 0;


% Calculate our max allowable value: 5 standard deviations above the mean
% of the central 1/2 second long window
s = movingstd(dsEMG,littleWindow,'central')*5;
dsEMG(:,2) = smooth(dsEMG(:,1),littleWindow) + s;
clear s;

% Let's try rounding this for now, it's easier than binning.
% dsEMG(:,2) = round(dsEMG(:,2));

% Set the minimum threshold to the baseline of the first epoch

% minT = scanning3(dsEMG(1:20*fs,:),2);


% Loop through bigWindows
for n = 0:(floor(size(dsEMG,1)/bigWindow)-1)
    % Calculate baseline of this bigWindow and save for later adjustment
    % The hard-coded 2 means don't set a baseline less than 2
    
    threshes(n+1) = scanning3(dsEMG(n*bigWindow+1:(n+1)*bigWindow,1),fs);    
end

% Instead of first epoch, try the mode?
minT = mode(threshes);
% not sure if we should scale up...
% threshes(threshes < minT) = minT;
threshes(threshes == 0) = minT;


% Apply scaling factor to each section of the dsEMG

for i = 1:size(threshes,1)-1
    % NEW STANDARDS (if > 16 above noise, ignore)
    %     if threshes(i) > (minT + 16)
    %         ndsEMG(bigWindow*(i-1)+1:bigWindow*i,1) = ...
    %             ones(size(bigWindow*(i-1)+1:bigWindow*i,2),1) * minT;
    %         threshes(i) = -1; % mark this a bad epoch
    %         badEps = [badEps ; i]; %#ok<AGROW>
    %     else
    %         ndsEMG(bigWindow*(i-1)+1:bigWindow*i)...
    %             = dsEMG(bigWindow*(i-1)+1:bigWindow*i) * minT / threshes(i);
    %     end
    ndsEMG(bigWindow*(i-1)+1:bigWindow*i)...
        = dsEMG(bigWindow*(i-1)+1:bigWindow*i) * minT / threshes(i);
end

ndsEMG(size(threshes,1)*bigWindow:end)...
    = dsEMG(size(threshes,1)*bigWindow:end,1) * minT / threshes(end);


end


% Find the baseline of a bigWindow epoch
function baseline = scanning3(dsEMG,fs)

lit_window = round((0.3)*fs)+1;

s = movingstd(dsEMG,lit_window,'central')*5;
dsEMG(:,2) = smooth(dsEMG(:,1),lit_window) + s;

baseline = 1;
cur_size = 0;
for i = 1:100
   in_here = dsEMG(dsEMG(:,2) > i & dsEMG(:,2) < (i + 1),2);
   if size(in_here,1) > cur_size
       cur_size = size(in_here,1);
       baseline = max(in_here);
   end
end

baseline = ceil(baseline);

end

