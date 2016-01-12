%% filterAnddsEMG Filter and rectify EMG signal
%   Apply two-stage (high/low pass), 5th order butterworth filter and rectify
%   data by taking the absoltue value of the filtered signal.

function dsEMG = filterAnddsEMG (highPass,lowPass,fs,EMG,sleepRecordStart,sleepRecordEnd)

[b,a] = butter (5,highPass/fs,'high');
[d,c] = butter (5,lowPass/fs,'low');
dsEMG = filtfilt (b,a,EMG(sleepRecordStart:sleepRecordEnd,1));
dsEMG = filtfilt(d,c,dsEMG);
dsEMG = abs(dsEMG); 

end