function dsEMG = filterAnddsEMG (highPass,lowPass,fs,EMG,sleepRecordStart,sleepRecordEnd)
%% filterAnddsEMG Filter and rectify EMG signal
%   dsEMG = filterAnddsEMG (highPass,lowPass,fs,EMG,sleepRecordStart,sleepRecordEnd)
%
%   Apply two-stage (high/low pass), 5th order butterworth filter and rectify
%   data by taking the absoltue value of the filtered signal.
%   
%   To omit an input, replace with 'nan'
%
%    Inputs:
%        highPass - high pass cutoff
%        lowPass - low pass cutoff (< fs/2)
%        fs - sampling rate
%        EMG - original EMG channel
%        sleepRecordStart - time, in data points, of hypnogam start relative
%                            to recording start
%        sleepRecordEnd - end of sleep scoring session
%     
%    Outputs:
%        dsEMG - filtered, rectified and truncated EMG for further processing

if isnan(sleepRecordStart)
    sleepRecordStart = 1;
end

if isnan(sleepRecordEnd)
    sleepRecordEnd = size(EMG,1);
end

if ~isnan(highPass)
    [b,a] = butter (5,highPass/fs,'high');
    dsEMG = filtfilt (b,a,EMG(sleepRecordStart:sleepRecordEnd,1));
    
    if ~isnan(lowPass)
        [d,c] = butter (5,lowPass/fs,'low');
        dsEMG = filtfilt(d,c,dsEMG);
    end
    
elseif ~isnan(lowPass)
    [d,c] = butter (5,lowPass/fs,'low');
    dsEMG = filtfilt(d,c,EMG(sleepRecordStart:sleepRecordEnd,1));
end

dsEMG = abs(dsEMG); 

end