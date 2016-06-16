function t = dt_rev1(EMG,fs)
%% t = dt(EMG,fs)
% Create a dynamic threshold that is the length of the EMG signal. This
% file requires the image processing toolbox. The output, t, has three
% columns: the first is the baseline level, the second is the low threshold
% (which is either 2 uv > baseline, or inf if > 15 uv) and third is the
% high threshold. Lots of room for experimentation on the lengths of the
% min and max filters, but currently the 0.5 second lookback max filter is
% good for avoiding EKG interference and other spurious, closely spaced
% spikes.

% Create a smoothed signal to determine the baseline from. Smoothed signal
% is the moving average + five standard deviations. Moving average alone
% tends to underestimate the baseline
N = round((0.3)*fs)+1; h = repmat(1/N,1,N);
E_x = filter(h,1,EMG);
E_xsq = filter(h,1,EMG.^2);

sd = E_xsq - E_x.^2;
t = E_x + 5 * sd;

% determine the baseline with two lookback filters. First, a 0.5 second
% lookback max filter is applied to the smoothed signal, then a 60 second
% lookback min filter.
t = imdilate(t,ones(fs/2,1));
t = imerode(t,ones(fs*60,1));

t(t > max(EMG)) = max(EMG);
t(t < 0.5) = 3;
t(:,2) = t(:,1) + 2; % low thresh is 2 above baseline
t(:,3) = t(:,1) + 8; % high thresh is 8 above baseline

t(t(:,1) > 15,2:3) = inf; % turn it off when noise is higher than 15