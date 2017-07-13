lEMG = subj_struct.Signals(2).data;
ss = round(subj_struct.EDFStart2HypnoInSec) * 500 + 1;
es = subj_struct.CISRE_Hypnogram;
se = ss + size(es, 1) * 30 * 500;

if se > size(lEMG,1), se = size(lEMG,1); end

if size(find(isnan(lEMG(ss:se)),1)) > 0
    se = ss + find(isnan(lEMG(ss:se)),1) - 2; 
end 

lEMG = lEMG(ss:se);

clear ss es se

[b,a] = butter(5,10/(500/2),'high');
[d,c] = butter(5,225/(500/2),'low');
ldsEMG = filtfilt(b,a,lEMG);
ldsEMG = filtfilt(d,c,ldsEMG);

clear a b c d

ldsEMG = abs(ldsEMG);

% Length, in seconds, of the lookback min and max filters.
max_filter_length = 0.5; 
min_filter_length = 60;

% Create a smoothed signal to determine the baseline from. Smoothed signal
% is the moving average + five standard deviations. Moving average alone
% tends to underestimate the baseline
N = round((0.3)*500)+1; h = repmat(1/N,1,N);
avg_filt = filter(h,1,ldsEMG);
E_xsq = filter(h,1,ldsEMG.^2);

sd = E_xsq - avg_filt.^2;
sd_filt = avg_filt + 5 * sd;

% determine the baseline with two lookback filters. First, a 0.5 second
% lookback max filter is applied to the smoothed signal, then a 60 second
% lookback min filter. These values are estimates, and need to be evaluated
% on a large dataset
t = imdilate(sd_filt,ones(500*max_filter_length,1));
t = imerode(t,ones(500*min_filter_length,1));

clear max_filter_length min_filter_length
clear N h E_xsq sd

t(t > max(ldsEMG)) = max(ldsEMG);
t(t < 0.5) = 3;
t(:,2) = t(:,1) + 2; % low thresh is 2 above baseline
t(:,3) = t(:,1) + 8; % high thresh is 8 above baseline

t(t(:,1) > 16,2:3) = inf; % turn it off when noise is higher than 15