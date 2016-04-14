function dsEMG = butter_rect(pars,EMG,ss,se,varargin)
%% dsEMG = butter_rect(pars,fs,EMG)
% Apply low and high pass, 5th order butterworth bandpass filters. Also
% truncate to start and end of record and rectify.

[b,a] = butter(5,pars.hipass/pars.fs,'high');
[d,c] = butter(5,pars.lopass/pars.fs,'low');
dsEMG = filtfilt(b,a,EMG(ss:se,1));
dsEMG = filtfilt(d,c,dsEMG);

if ~strcmp('noabs',varargin)
    dsEMG = abs(dsEMG);    
end


end