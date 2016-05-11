function [es,ss,se,apd,ard,hgs] = errcheck_ss(psg_struct,LAT,RAT,fs)
%% [es,ss,se] = errcheck_ss(psg_struct,LAT,RAT,fs)
% Extracts and handles epochStage vector (es), start and end of the
% sleep record (ss/se), apnea/arousal vectors (apd/ard) and hynogram start
% time (hgs).



% Get sleep start and end
try
    ss = round(psg_struct.EDFStart2HypnoInSec) * fs + 1;
catch
    warning('Reference to non-existent field ''EDFStart2HypnoInSec''');
    ss = 1;
end

% Get sleep end and hypnogram
try
    es = psg_struct.CISRE_Hypnogram;
    se = ss + size(es, 1) * 30 * fs;
    
catch
    warning(['Reference to non-existent field ''CISRE_Hypnogram''... ',...
        'Assuming (possibly incorrectly) that TST < 8 hours... ',...
        'Sleep staging information will be unavailable']);
    
    se = ss + 960 * 30 * fs;
    es = zeros(960,1);
end

% Get apnea, arousal data
try
    apd = psg_struct.CISRE_Apnea;   
catch
    warning('Reference to non-existent field ''CISRE_Apnea''');
    apd = {0,0,0};
end

try
    ard = psg_struct.CISRE_Arousal;   
catch
    warning('Reference to non-existent field ''CISRE_Arousal''');
    ard = {0,0,0};
end

try
    hgs = psg_struct.CISRE_HypnogramStart;
catch
    warning('Reference to non-existent field ''CISRE_HypnogramStart''');
    hgs = '2000-01-01 00:00:00';
end

% Make sure the sleep record end (from size of hypnogram) is not beyond the
% end of the EMG recording. The two channels should always be the same
% length, but check to make sure.
if se >= max(size(RAT,1),size(LAT,1))
    se = min(size(RAT,1),size(LAT,1)); 
end

% If there are any NaNs in the record, filtering will fail. We must end the
% record when a NaN is found
if size(find(isnan(LAT(ss:se)),1)) > 0
    se = find(isnan(LAT(ss:se)),1) - 1; 
end 
if size(find(isnan(RAT(ss:se)),1)) > 0
    se = find(isnan(RAT(ss:se)),1) - 1; 
end 

end