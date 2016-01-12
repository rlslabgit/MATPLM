% d is 'fraction of a second' as in $$ fs/d $$
function [goodLM,badLM] = giveLowMedian(dsEMG,LM1,min)

goodLM = cell(4,1);
% Calculate duration, probably don't need this though
LM1(:,3) = (LM1(:,2) - LM1(:,1))/500;

% Add column with median values
for i = 1:size(LM1,1)
    LM1(i,4) = median(dsEMG(LM1(i,1):LM1(i,2)));
end

LM = shrinkWindow(LM1,dsEMG,500,min,1); 
goodLM{1} = LM(LM(:,4) > min,:); % full second core
badLM = LM(LM(:,4) < min,:);

badLM = shrinkWindow(badLM,dsEMG,500,min,4/3);
goodLM{2} = badLM(badLM(:,4) > min,:); % 3/4 second core
badLM = badLM(badLM(:,4) < min,:);

badLM = shrinkWindow(badLM,dsEMG,500,min,2);
goodLM{3} = badLM(badLM(:,4) > min,:); % 1/2 second core
badLM = badLM(badLM(:,4) < min,:);

badLM = shrinkWindow(badLM,dsEMG,500,min,4);
goodLM{4} = badLM(badLM(:,4) > min,:); % 1/4 second core
badLM = badLM(badLM(:,4) < min,:);
end


% A different method of checking for a movement within the movement. This
% searches for any 0.5 second window where the median is above noise level.
function LM = shrinkWindow(LM,dsEMG,fs,min,d)

empty = find(LM(:,4) < min);

med = @(a,b) median(dsEMG(a:b)); % macro to get median

for i = 1:size(empty,1)
    
    % Record the original start, stop and median
    initstart = LM(empty(i),1);
    initstop = LM(empty(i),2);
    a = med(initstart,initstop);
    
    % Now, the start and stop times that will shift
    start = LM(empty(i),1); stop = start + fs/d;
    
    % Loop through 1/2 second windows of the movement, skipping along at
    % 1/10 second.
    while a < min && stop < initstop;
        a = med(start,stop);
        start = start + fs/10; stop = start + fs/d;
    end
    
    % Mark the new median in the original array
    LM(empty(i),4) = a;
end

end