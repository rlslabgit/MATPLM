function [dsEMG,threshes] = dynamicThreshold2(dsEMG,fs)
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


bigWindow = 20*fs; littleWindow = fs/2+1; minT = 2;

threshes = zeros(floor(size(dsEMG,1)/bigWindow),1);


% Calculate our max allowable value: 5 standard deviations above the mean
% of the central 1/2 second long window
s = movingstd(dsEMG,littleWindow,'central')*5;
dsEMG(:,2) = smooth(dsEMG(:,1),littleWindow) + s;

% Loop through bigWindows
for n = 0:(floor(size(dsEMG,1)/bigWindow)-1)        
    % Calculate baseline of this bigWindow and save for later adjustment
    threshes(n+1) = scanning3(dsEMG(n*bigWindow+1:(n+1)*bigWindow,:),minT); 
end

% Apply scaling factor to each section of the dsEMG

for i = 1:size(threshes,1)-1
    dsEMG(bigWindow*(i-1)+1:bigWindow*i)...
        = dsEMG(bigWindow*(i-1)+1:bigWindow*i) * minT / threshes(i);
end

dsEMG(size(threshes,1)*bigWindow:end)...
        = dsEMG(size(threshes,1)*bigWindow:end) * minT / threshes(end);
        
dsEMG = dsEMG(:,1);
end


% Look at the points where a spike is within 5 standard deviations of the
% mean for a window of size littleWindow. Take this max allow value as the
% baseline of a section.
function baseline = scanning3(dsEMG,minT)

h = dsEMG(dsEMG(:,2) > dsEMG(:,1),2);
g = histc(h,0:300);
[~,b] = max(g);

if b > minT
%     baseline = mode(h);
    baseline = b;
else
    baseline = minT;
end

end
