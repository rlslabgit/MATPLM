
function [CLM,PLM5,PLM10,epochStage] = lazyRun(StructName)
% addpath('C:\Users\Administrator\Documents\GitHub\MATPLM');

% Recommended initial conditions, particularly for batch processesing
in = struct('fs',500,'maxdur',10,'minIMI',5,'maxIMI',90,'lb1',0.5,'ub1',0.5,...
    'lopass',225,'hipass',25,'lb2',0.5,'ub2',0.5);

% Extract Info from structure 
% Get filepath for left and right EMG data
for i = 1:size(StructName.Signals,2)
    if strcmp(strtrim(StructName.Signals(i).label),'Left Leg')
        lidx = i;
    elseif strcmp(strtrim(StructName.Signals(i).label),'Right Leg')
        ridx = i;
    end
end
[lEMG] = StructName.Signals(lidx).data;
[rEMG] = StructName.Signals(ridx).data;


sleepRecordStart = StructName.EDFStart2HypnoInSec * in.fs + 1;
sleepRecordEnd = sleepRecordStart + ...
    size(StructName.CISRE_Hypnogram, 1) * 30 * in.fs;
[epochStage] = StructName.CISRE_Hypnogram;

% Check sleepRecordEnd for index out of bounds
if size(lEMG,1) > size(rEMG,1)
    emglength = size(lEMG,1);
else
    emglength = size(rEMG,1);
end
if sleepRecordEnd >= emglength
    sleepRecordEnd = emglength-1000;
elseif (isnan(lEMG(sleepRecordEnd,1)) || isnan(rEMG(sleepRecordEnd,1)))
     sleepRecordEnd = sleepRecordEnd - 15000; 
end

% Generate filtered EMG data
[ldsEMG] = filterAnddsEMG(in.hipass,in.lopass,in.fs,lEMG,sleepRecordStart,sleepRecordEnd);
[rdsEMG] = filterAnddsEMG(in.hipass,in.lopass,in.fs,rEMG,sleepRecordStart,sleepRecordEnd);
ldsEMG = dynamicThreshold2(ldsEMG,500);
rdsEMG = dynamicThreshold2(rdsEMG,500);

rLM = findIndices(rdsEMG,4,10,0.5,0.5,500);
lLM = findIndices(ldsEMG,4,10,0.5,0.5,500);

% Remove movements that don't pass median
[CLM] = lazyMP(rdsEMG,ldsEMG,rLM,lLM,epochStage,1);

[PLM5,~] = minimasterPlanForPLMt(CLM,5,in.fs,in.maxIMI,3,10);
[PLM10,~] = minimasterPlanForPLMt(CLM,10,in.fs,in.maxIMI,3,10);



end