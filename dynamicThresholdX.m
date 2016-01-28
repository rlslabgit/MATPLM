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


bigWindow = 15*fs; littleWindow = (0.1)*fs+1; 

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
% The hard-coded 2 means don't set a baseline less than 2
minT = scanning3(dsEMG(1:20*fs,:),2);


% Loop through bigWindows
for n = 0:(floor(size(dsEMG,1)/bigWindow)-1)        
    % Calculate baseline of this bigWindow and save for later adjustment
    threshes(n+1) = scanning3(dsEMG(n*bigWindow+1:(n+1)*bigWindow,:),minT); 
end

% Apply scaling factor to each section of the dsEMG

for i = 1:size(threshes,1)-1
    % NEW STANDARDS (if > 16 above noise, ignore)
    if threshes(i) > (minT + 16)
        ndsEMG(bigWindow*(i-1)+1:bigWindow*i,1) = ...
            ones(size(bigWindow*(i-1)+1:bigWindow*i,2),1) * minT;
        badEps = [badEps ; i]; %#ok<AGROW>
    else
        ndsEMG(bigWindow*(i-1)+1:bigWindow*i)...
            = dsEMG(bigWindow*(i-1)+1:bigWindow*i) * minT / threshes(i);
    end
end

ndsEMG(size(threshes,1)*bigWindow:end)...
        = dsEMG(size(threshes,1)*bigWindow:end,1) * minT / threshes(end);
        

end


% Find the baseline of a bigWindow epoch
function baseline = scanning3(dsEMG,minT)

% h = dsEMG(dsEMG(:,2) > dsEMG(:,1),2);

% The ol' histogram try
% g = histc(h,0:2:300);
% [~,b] = max(g);
% 
% if b > minT
%     baseline = mode(h);
%     baseline = b;
% else
%     baseline = minT;
% end

% Rounded mode
% baseline = mode(h);

% Longest run
tol = 2;
ds = abs(diff(dsEMG(:,2)));
ds = ds < tol;

A = findseq(+ds);
if isempty(A) %|| max(A(:,4),1) == 0 % seen when device unplugged. Ignore this section
    baseline = minT + 100;
else
    indx = find(A(:,4) == max(A(:,4)));
    baseline = floor(median(dsEMG(A(indx,2)+1:A(indx,3),2)));
    % baseline = A(find(A(:,4) == max(A(:,4)),1));
end

   end
