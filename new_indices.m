function LM = new_indices(oEMG, EKG, fs)
%% LM = new_indices(oEMG, fs)
% remember, this takes filtered, unrectified EMG...

min_high = 0.5;
min_low = 0.5;

EMG = abs(oEMG); %
LM = [];

window_size = fs * 30;  % try a five second sliding window


% turn off peak warning, it just means there are no peaks in this epoch
warning('off','signal:findpeaks:largeMinPeakHeight')

% windowing can be greatly sped up, but don't worry for now...
% ok, so what are we going to do about the edges of the windows?
for n = 0:0.5:(floor(size(EMG,1)/window_size)-1)
    interest = EMG(n*window_size+1:(n+1)*window_size,1);
    interstk = EKG(n*window_size+1:(n+1)*window_size,1);
    bl = findbl(interest,fs);
    
    lowt = bl + 2; % low threshold is two above baseline
    hit = lowt + 6; % this really should be variable
    
    % check for EKG??
    [~, rel] = findpeaks(interest.^2,'MinPeakHeight',hit.^2,...
        'MinPeakDistance',0.150*500);
    rel(2:end,2) = (rel(2:end,1) - rel(1:end-1,1))/fs;
    beats = rel(:,2) > 0.7 & rel(:,2) < 1.2;
    
    if size(rel,1) > 30 && sum(beats)/size(rel,1) > 0.3
        plot(interest)
        interest = removeEKG(interest,interstk,fs);
        bl = findbl(interest,fs);
        lowt = bl + 2; % low threshold is two above baseline
        hit = lowt + 6; % this really should be variable
        plot(interest)
    end
    
    
    % so now, we actualy search for the correct threshold and do
    % cut low median at the same time
    lm_here = findIndices(interest,lowt,hit,min_high,min_low,fs);
    
    
    % ignore this branch if we have no LMs (find indices returns [0;0])
    if isempty(lm_here) || lm_here(1,1) == lm_here(1,2)
        continue
    end
        
    lm_here = cutLowMedian(interest,lm_here,lowt-2,fs);
    
    % adjust start times to this window
    lm_here(:,1) = lm_here(:,1) + n*window_size+1;
    lm_here(:,2) = lm_here(:,2) + n*window_size+1;      
        
    LM = [LM ; lm_here];                  
end

warning('on','signal:findpeaks:largeMinPeakHeight') % turn back on

% TODO: remove identical or overlapping
LM = check_edges(LM, min_low, fs);
LM = LM(:,1:2); % only keep start and stop

end

% check if we have movements that continue from one window to the next
function LM = check_edges(fLM, min_low, fs)

% first, sort by start time
LM = sortrows(fLM);
%LM = getIMI(LM, fs);
LM(2:end,4) = (LM(2:end,1) - LM(1:end-1,2))/fs;
LM(1,4) = 9999;

% we may need to run this twice if there are multiple overlapping movements
while sum(LM(:,4) < min_low) > 0
    
    negs = find(LM(:,4) < min_low); % these movements should overlap
    negs(:,2) = LM(negs-1,2); % endpoints of the earlier occuring movement
    negs(:,3) = LM(negs(:,1),2); % endpoints of second movement
    
    LM(negs(:,1),2) = max(negs(:,2),negs(:,3));
    LM = LM(LM(:,4) > 0.5,:);    
    LM(2:end,4) = (LM(2:end,1) - LM(1:end-1,2))/fs;
    display('one loop');
end

end


% Find the baseline of a bigWindow epoch
function baseline = findbl(EMG, fs)
lit_window = round((0.3)*fs)+1;

s = movingstd(EMG,lit_window,'central')*5;
EMG(:,2) = smooth(EMG(:,1),lit_window) + s;

baseline = 1;
cur_size = 0;
for i = 1:100
   in_here = EMG(EMG(:,2) > i & EMG(:,2) < (i + 1),2);
   if size(in_here,1) > cur_size
       cur_size = size(in_here,1);
       baseline = max(in_here);
   end
end

baseline = ceil(baseline);
end
