%% dynamicThreshold normalizes dsEMG vector to a baseline noise level of 2
%
%   bigwindow: size in data points of the normalizing epoch.
%       (default is 20000, or 40 seconds when fs = 500)
%   littlewindow: size in data points of inter-epoch window to determinTe
%       baseline. i.e. number of consecutive data points where max spike is
%       within five sd of the mean
%      (default is 1000, or 2 seconds when fs = 500)
%
% Big window must be at least ten times the size of the little window.
function [dsEMG,threshes,n] = dynamicThreshold(dsEMG,fs)


bigWindow = 20*fs; littleWindow = fs; minT = 2;

threshes = zeros(floor(size(dsEMG,1)/bigWindow),1);

% Loop through 60 second windows
for n = 0:(floor(size(dsEMG,1)/bigWindow)-1)        
    % Calculate baseline of this bigWindow
    baseline = scanning3(dsEMG(n*bigWindow+1:(n+1)*bigWindow),littleWindow); 
    % Save this baseline to a vector for inspection
    threshes(n+1) = ceil(baseline); 
end

% Get rid of '-99's
% threshes = fixHoles(threshes);
threshes(threshes == -99) = 20;

for i = 1:size(threshes,1)-1
    dsEMG(bigWindow*(i-1)+1:bigWindow*i)...
        = dsEMG(bigWindow*(i-1)+1:bigWindow*i) * minT / threshes(i);
end

dsEMG(size(threshes,1)*bigWindow:end)...
        = dsEMG(size(threshes,1)*bigWindow:end) * minT / threshes(end);
end


%% Search for 5 s (number needs experimentation) window in which the
% maximum spike is within 5 standard deviations (exp?) of the mean. If no
% such window can be found, the max spike is hardcoded to 2, in order to
% maintain the original dsEMG (since the signal is unlikely to be noise if
% it continues for the whole window)
function baseline = scanning3(dsEMG,littleWindow)

% Let's save a vector of five possible values and pick the median
x = zeros(7,2);

for n = 0:3:18
    start = 0 + floor(n*littleWindow*1.05);
    stop = start + littleWindow; 
    [maxSpike,maxAllow] = searchForThreshold(dsEMG,start,stop);
    %while (maxSpike > 20 || maxSpike > maxAllow)
    while (maxSpike > maxAllow && ~isnan(maxSpike))
        start = stop;
        stop =  start + littleWindow;
        if stop < max(size(dsEMG))
            [maxSpike,maxAllow] = searchForThreshold(dsEMG,start,stop);
        else
            maxSpike = nan;
            maxAllow = nan; % Want loop to terminTate eventually
        end
    end
   
    x((n+3)/3,1) = maxSpike;
    x((n+3)/3,2) = maxAllow;
end

x(x == 0) = nan;

if sum(sum(isnan(x))) ~= 14
    maxSpike = nanmedian(x(:,1));
    maxAllow = nanmedian(x(:,2));

    baseline = maxSpike;
else
    baseline = 20;
end

end


%% DeterminTes the maximum spike in a section of dsEMG, and the maximum
%  allowable voltage for this section to represent the lower bound.
function [maxSpike,maxAllow] = searchForThreshold(dsEMG,start,stop)

avg = mean(dsEMG(start+1:stop));
st = std(dsEMG(start+1:stop));
maxSpike = max(dsEMG(start+1:stop));

maxAllow = avg + st*5;

if min(dsEMG(start+1:stop)) <= 0
    maxAllow = nan;
end

end