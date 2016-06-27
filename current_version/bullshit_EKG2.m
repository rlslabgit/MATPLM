function [ecg, locs, hr] = bullshit_EKG2(EKG)

fs = 500;

ecg = downsample(EKG, fs/100); % downsample to 100 hz
fs = 100;

f1=0.5; %cuttoff low frequency to get rid of baseline wander
f2=45; %cuttoff frequency to discard high frequency noise

Wn=[f1 f2]*2/fs; % cutt off based on fs
N = 7; % order of 3 less processing
[a,b] = butter(N,Wn); %bandpass filtering
ecg = filtfilt(a,b,ecg);

ecg = ecg/prctile(ecg,97);
ecg = ecg.^2;
ecg(:,2) = 2;

a = ecg(:,1) > 2; a = +a;
[~,locs] = findpeaks(a,'minpeakdistance',0.4*100);
a(locs,2) = 1;

ecg(:,2) = 0; ecg(locs,2) = ecg(locs,1);
plot(ecg);

locs(2:end,2) = (locs(2:end,1)-locs(1:end-1,1))/fs;


hr_size = 30*fs; hr_loc = 1;

hr = [];

while hr_loc + hr_size < size(ecg,1)
    tmp_hr = locs(locs(:,1) >= hr_loc & locs(:,1) <= (hr_loc + hr_size),1);
    hr = [hr ; size(tmp_hr,1)];
    
    
    hr_loc = hr_loc + hr_size;
end

hr(:,2) = hr(:,1) * (60/hr_size*fs); % bpm for each epoch
hr(:,3) = 1:size(hr,1); hr(:,3) = ceil(hr(:,3)/(30/(hr_size/fs)));
hr(2:end,4) = hr(2:end,2) - hr(1:end-1,2);



