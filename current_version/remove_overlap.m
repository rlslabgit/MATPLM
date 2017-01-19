function m = remove_overlap(start_stop,fs,t)
%% m = remove_overlap(start_stop,fs)
%
% Simple function to remove and combine overlapping movements in an array
% based on the start and stop times in data points. All it does is sort
% according to start time as far as preprocessing is concerned
%
% input:
%   start_stop - LM-like array with start col 1 and stop col 2
%   fs - sampling rate
%   t - extra time to overlap I guess?
%
% PS 30Aug16

win = t * fs;

% sort array
start_stop = sortrows(start_stop,1); % sort by start time

% distance to next movement
m = start_stop;
i = 1;

while i < size(m,1)
    % make sure to check if this is correct logic for the half second
    % overlap period...
    if isempty(intersect(m(i,1):m(i,2),(m(i+1,1)-win):m(i+1,2)))
        i = i+1;
    else
        m(i,2) = max(m(i,2),m(i+1,2));
        m(i+1,:) = [];
    end
end

end