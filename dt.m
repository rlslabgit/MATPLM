function t = dt(EMG,fs)
%% t = dt(EMG,fs)
% another attempt at a dynamic threshold, using the strategy described by
% Moore and Diego

lit_window = round((0.3)*fs)+1;
s = movingstd(EMG(:,1),lit_window,'central')*5;
t = smooth(EMG(:,1),lit_window) + s;

t = imdilate(t,ones(fs,1));
t = imerode(t,ones(fs*60,1));

t(t < 0.5) = 3;
% t(t(:,1) <= 5,2) = t(t(:,1) <= 5,1) + 2; % low threshold
% t(t(:,1) <= 5,3) = t(t(:,1) <= 5,1) + 8; % high threshold
% 
% t(t(:,1) > 5, 2) = t(t(:,1) > 5, 1)*3;
% t(t(:,1) > 5, 3) = t(t(:,1) > 5, 1)*3;

t(:,2) = t(:,1) + 2; % low thresh is 2 above baseline
t(:,3) = t(:,1) + 8; % high thresh is 8 above baseline

t(t(:,1) > 15,2:3) = inf; % turn it off when noise is higher than 15