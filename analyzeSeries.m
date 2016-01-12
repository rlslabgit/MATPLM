function [runs,stats] = analyzeSeries(PLM)
%% Group PLM by sequences and return selected statistics
% [runs,stats] = analyzeSeries(PLM)
%
% analyzeSeries divides a PLM array into sections based on the locations of
% breakpoints. Statistics are labelled at the bottom of this file, because
% creating a table is a waste of time in this immature method.
%
% Inputs:
%   PLM - an array of periodic leg movements. Should include all movements
%       in wake and sleep so series are accurately depicted
%
% Outputs:
%   runs - a cell array containing all the movements, grouped by columns
%       according to their corresponding run.
%   stats - some various metrics. Changing very often right now (9/16)

fs = 500;

breaks = find(PLM(:,9) == 1);
runs = cell(4,size(breaks,1));

% First loop through the breakpoints (ignoring the last movement first)
for i = 1:size(breaks,1)-1
    % Then, go through the movements within that run
    for j = breaks(i):breaks(i+1)-1
        runs{j-breaks(i)+1,i} = PLM(j,:);
    end
    
end

% Finish off the last run
last = breaks(end,1);
while last < size(PLM,1)
   runs{last-breaks(end,1)+1,size(breaks,1)} = PLM(last,:);    
   last = last+1;
end


% Try and do some statistics.
stats = zeros(size(runs,2),5)';

for i = 1:size(runs,2)
   m = cell2mat(runs(:,i));
   stats(1,i) = size(m,1);
   stats(5,i) = mode(m(:,6));
   stats(6,i) = (m(end,2)-m(1,1))/fs/60;
   stats(7,i) = floor(m(1,8)/2);
      
   % Only look at movement in sleep for IMI stuff
   m = m(m(:,6) > 0 & m(:,9) ~= 1,:);
   stats(2,i) = size(m,1);
   stats(3,i) = nanmean(m(:,4));
   stats(4,i) = nanstd(m(:,4));
end

% row 1: number of movements in run (including wake)
% row 2: number of movements in sleep
% row 3: mean IMI
% row 4: std IMI
% row 5: mode sleep stage (including wake)
% row 6: run duration in minutes
% row 7: approximate start time in minutes

end
