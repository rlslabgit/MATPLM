%  Master script
%  Creates LM by finding location of EMG indices (from dsEMG) that meets 
%      the low Threshold, high Threshold, minLowDuration, minHighDuration
%  Creates CLM from LM by removing leg movements that are too long
%  Creates PLM from CLM using maximum inter-movement intervals and minRunLength
%  Creates runsArray that show the beginning and end of a PLM
%  Create PLM, PLMS, PLMW
%  TST = total sleep time

% Combines two legs

% Major changes last made by Tony, April 21 2015
% Calculates apnea and arousal events
% Patrick made aesthetic changes, including removal of unnecessary
% functions, June 18 2015

% Many changes throughout July. Streamlined code, added output of PLM array
% minus apnea-related events, etc.

% This is now a tiny version that only outputs the bare minimum (everything
% can be extracted from these 3.


function [CLM,PLM,rCLM,lCLM,PLMnoAp,CLMnoAp] = miniCOMBOmasterPlanForPLM(rdata,ldata,rlowThreshold,llowThreshold,...
    rhighThreshold,lhighThreshold,minLowDuration,minHighDuration,fs,maxDuration,...
    epochStage,numSecsPerEpoch,maxIMIDuration,minNumIMI,ApneaData,...
    ArousalData,HypnogramStart,lb1,ub1,lb2,ub2,doMed)

rLM = findIndices(rdata,rlowThreshold,rhighThreshold,minLowDuration,minHighDuration,fs);
lLM = findIndices(ldata,llowThreshold,lhighThreshold,minLowDuration,minHighDuration,fs);

% Add duration to LM arrays and remove those that are too long
% Store the long movements, just in case, but they're not outputted right
% now
rLM(:,3) = (rLM(:,2)- rLM(:,1)) / fs; lLM(:,3) = (lLM(:,2)- lLM(:,1)) / fs;
rLong = rLM(rLM(:,3) > maxDuration,:); lLong = lLM(lLM(:,3) > maxDuration,:);

% Don't get rid of long duration... they now end a movement
% rLM = rLM(rLM(:,3) < maxDuration,1:2);
% lLM = lLM(lLM(:,3) < maxDuration,1:2);

if doMed == 1
    rLM = cutLowMedian(rdata,rLM,rlowThreshold-2,fs);
    lLM = cutLowMedian(ldata,lLM,llowThreshold-2,fs);
end

% Combine left and right and sort.
rLM(:,13) = 1; lLM(:,13) = 2;
combLM = [rLM;lLM];
combLM = sortrows(combLM,1);
CLM = removeOverlap(combLM,fs);




% Throw an exception if the record contains no leg movements, because
% later steps will fail
try
    CLM(1,1); % Try to access first element
catch
    msgID = 'MasterPlan:EmptyLM';
    msg = 'No LM detected in this record.';
    baseException = MException(msgID,msg);
    
    throw(baseException);
end




% Add duration of leg movements (col 3), IMI (col 4), sleep stage (col
% 6). Col 5 is reserved for PLM marks later
CLM(:,3) = (CLM(:,2)-CLM(:,1))/fs;
CLM = getIMI(CLM, fs);
CLM(:,6) = epochStage(round(CLM(:,1)/numSecsPerEpoch/fs+.5));

% Add movement start time in minutes (col 7) and sleep epoch number
% (col 8)
CLM (:,7) = CLM(:,1)/(fs * 60);
CLM (:,8) = round (CLM (:,7) * 2 + 0.5);

% Average left and right leg dsEMG in order to calculate the area of a
% leg movement. May change this at some point to the area on each leg.
% Add area (col 10)
combLegdsEMG = (ldata + rdata)/2;
CLM = findAreaLM(CLM,fs,combLegdsEMG);

% Mark movements (col 9) with breakpoints if they are preceeded by an
% IMI > max allowable duration or have too long movement durations. There
% also must be a breakpoint after a too long movement, so that a PLM run
% does not begin on a movement > maxdur
CLM(:,9) = CLM(:,4) > maxIMIDuration | CLM(:,3) > maxDuration;
aftLong = find(CLM(:,3) > maxDuration) + 1;
aftLong = aftLong(aftLong < size(CLM,1));
CLM(aftLong,9) = 1;

BPloc = BPlocAndRunsArray(CLM,minNumIMI);

% Add apnea events (col 11) and arousal events (col 12)
CLM = PLMApnea(CLM,ApneaData,HypnogramStart,lb1,ub1,fs);
CLM = PLMArousal(CLM,ArousalData,HypnogramStart,lb2,ub2,fs);

% Mark movements (col 5) that occur with at least the minimum number
% of inter-movement intervals (minNumIMI);
CLM = markPLM3(CLM,BPloc,fs);

PLM = CLM(CLM(:,5) == 1,:);


% Begin calculation of PLM w/ apnea events removed
CLMnoAp = CLM(CLM(:,11) == 0,:);
CLMnoAp = getIMI(CLMnoAp,fs);
BPlocnoAp = BPlocAndRunsArray(CLMnoAp,minNumIMI);
CLMnoAp = markPLM3(CLMnoAp,BPlocnoAp,fs);
PLMnoAp = CLMnoAp(CLMnoAp(:,5) == 1,:);


% Create CLM arrays for each leg seperately
rCLM(:,1:2) = rLM(:,1:2);
rCLM(:,3) = (rLM(:,2)-rLM(:,1))/fs;
rCLM = getIMI(rCLM, fs);
rCLM(:,6) = epochStage(round(rCLM(:,1)/numSecsPerEpoch/fs+.5));
rCLM(:,7) = rCLM(:,1)/(fs * 60);
rCLM(:,8) = round (rCLM (:,7) * 2 + 0.5);
rCLM = findAreaLM(rCLM,fs,rdata);
rCLM(:,9) = rCLM(:,4) > maxIMIDuration | rCLM(:,3) > maxDuration;
BPloc = BPlocAndRunsArray(rCLM,minNumIMI);
rCLM = markPLM3(rCLM,BPloc,fs);

lCLM(:,1:2) = lLM(:,1:2);
lCLM(:,3) = (lLM(:,2)-lLM(:,1))/fs;
lCLM = getIMI(lCLM, fs);
lCLM(:,6) = epochStage(round(lCLM(:,1)/numSecsPerEpoch/fs+.5));
lCLM(:,7) = lCLM(:,1)/(fs * 60);
lCLM(:,8) = round (lCLM (:,7) * 2 + 0.5);
lCLM = findAreaLM(lCLM,fs,ldata);
lCLM(:,9) = lCLM(:,4) > maxIMIDuration | lCLM(:,3) > maxDuration;
BPloc = BPlocAndRunsArray(lCLM,minNumIMI);
lCLM = markPLM3(lCLM,BPloc,fs);

end

%Col 1: start location of leg movement
%Col 2: stop location of leg movement
%Col 3: Duration of leg movement
%Col 4: Inter-movement Interval between start of each leg movement
%Col 5: PLM (1 is PLM; 0 is no PLM)
%Col 6: Sleep Stage
%Col 7: starting leg movement location in minutes
%Col 8: sleep epoch number that for the start of the leg movement
%Col 9: Break points in PLM (1 is break point, 0 is not)
%Col 10: Area of each leg movement
%Col 11: Apnea event
%Col 12: Arousal event
%Col 13: Uni/bilateral (1 = left, 2 = right, 3 = both)

%% find area of each leg movement
function [LM] = findAreaLM(LM,fs,dsEMG)
for i = 1:size(LM,1)
    LM(i,10) = sum(dsEMG(LM(i,1):LM(i,2)))/fs;
end
end