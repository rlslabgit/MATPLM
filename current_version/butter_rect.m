function dsEMG = butter_rect(pars,EMG,ss,se,varargin)
%% dsEMG = butter_rect(pars,fs,EMG)
% Apply low and high pass, 5th order butterworth bandpass filters. Also
% truncate to start and end of record and rectify.
%
% inputs:
%   - pars - structure returned by 'getInput2.m'
%   - EMG - raw EMG signal to filter
%   - ss - start time (in data points)
%   - se - end time (in data points)
%
% optional input:
%   - 'rect' - also rectifies the signal by using absolute value    

[b,a] = butter(5,pars.hipass/pars.fs,'high');
[d,c] = butter(5,pars.lopass/pars.fs,'low');
dsEMG = filtfilt(b,a,EMG(ss:se,1));
dsEMG = filtfilt(d,c,dsEMG);

if strcmp('rect',varargin)
    dsEMG = abs(dsEMG);    
end


end