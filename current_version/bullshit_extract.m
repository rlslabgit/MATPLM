function [rEMG,lEMG,EKG] = bullshit_extract(psg,fs)

lbls = extractfield(psg.Signals,'label');
lidx = find(not(cellfun('isempty', strfind(lbls,'Left'))));
ridx = find(not(cellfun('isempty', strfind(lbls,'Right'))));
kidx = find(not(cellfun('isempty', strfind(lbls,'EKG'))));

lEMG = psg.Signals(lidx(1)).data;
rEMG = psg.Signals(ridx(1)).data;
EKG = psg.Signals(kidx(1)).data; %%%%%%% CHANGE THIS BACK

ss = round(psg.EDFStart2HypnoInSec) * fs + 1; % sleep start
se = ss + size(psg.CISRE_Hypnogram, 1) * 30 * fs; % sleep end

se = min(se,size(lEMG,1)); 
if ~isempty(find(isnan(lEMG)))
   tmp = find(isnan(lEMG));
   se = tmp(1) -1;
end

%rEMG = filterAnddsEMG (20,0.45*fs,fs,rEMG,ss,se);
lEMG = filterAnddsEMG (20,0.45*fs,fs,lEMG,ss,se);
%EKG = filterAnddsEMG (1,0.45*fs,fs,EKG,ss,se); % just low pass
EKG = EKG(ss:se);
end
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