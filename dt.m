function t = dt(EMG,fs)
%% t = dt(EMG,fs)
% another attempt at a dynamic threshold, using the strategy described by
% Moore and Diego

lit_window = round((0.3)*fs)+1;
s = movingstd(EMG(:,1),lit_window,'central')*5;
t = smooth(EMG(:,1),lit_window) + s;

t = imdilate(t,ones(fs,1));
t = imerode(t,ones(fs*60,1));