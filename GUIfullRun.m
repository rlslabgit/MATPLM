%% Very simplified full run so i can test the GUI


function [ldsEMG,rdsEMG] = GUIfullRun(StructName)

in = struct('fs',500,'maxdur',10,'minIMI',5,'maxIMI',90,'lb1',0.5,'ub1',0.5,...
    'lb2',0.5,'ub2',0.5,'lopass',225,'hipass',25);
doDynamic = 1;
doMed = 0;

% Extract Info from structure 
% Get filepath for left and right EMG data
for i = 1:length(StructName.Signals)
    if strcmp(strtrim(StructName.Signals(i).label),'Left Leg')
        lidx = i;
    elseif strcmp(strtrim(StructName.Signals(i).label),'Right Leg')
        ridx = i;
    end
end
[lEMG] = StructName.Signals(lidx).data;
[rEMG] = StructName.Signals(ridx).data;

% Check sleepRecordEnd for index out of bounds
if length(lEMG) > length(rEMG)
    emglength = length(lEMG);
else
    emglength = length(rEMG);
end

sleepRecordStart = StructName.EDFStart2HypnoInSec * in.fs + 1;
sleepRecordEnd = sleepRecordStart + ...
    size(StructName.CISRE_Hypnogram, 1) * 30 * in.fs;
[epochStage] = StructName.CISRE_Hypnogram;

if sleepRecordEnd >= emglength
    sleepRecordEnd = emglength-1000;
elseif (isnan(lEMG(sleepRecordEnd,1)) || isnan(rEMG(sleepRecordEnd,1)))
     sleepRecordEnd = sleepRecordEnd - 15000; 
end

ApneaData = StructName.CISRE_Apnea;
ArousalData = StructName.CISRE_Arousal;
HypnogramStart = StructName.CISRE_HypnogramStart;

% Generate filtered EMG data
[ldsEMG] = filterAnddsEMG(in.hipass,in.lopass,in.fs,lEMG,sleepRecordStart,sleepRecordEnd);
[rdsEMG] = filterAnddsEMG(in.hipass,in.lopass,in.fs,rEMG,sleepRecordStart,sleepRecordEnd);

if doDynamic == 1
    ldsEMG = dynamicThreshold2(ldsEMG,500);
    rdsEMG = dynamicThreshold2(rdsEMG,500);
     
    % Run ComboMasterPlan w/ thresholds at 4 and 10 
    % Uses normalized dsEMG vectors, but returns originals.
    % May be better to return new vectors, but I don't know if that makes
    % sense
    [CLM,PLM,rCLM,lCLM,PLMnoAp,CLMnoAp] = miniCOMBOmasterPlanForPLM(rdsEMG,ldsEMG,...
        4,4,10,10,0.5,0.5,in.fs,in.maxdur,epochStage,30,in.maxIMI,3,...
        ApneaData,ArousalData,HypnogramStart,in.lb1,in.ub1,in.lb2,in.ub2,doMed);
    
else
    % Calculates low threshold from dsEMG data
    llowThreshold = scanning2(ldsEMG,in.fs);
    rlowThreshold = scanning2(rdsEMG,in.fs);
    
    % Run ComboMasterPlan w/ auto thresholds
    [CLM,PLM,rCLM,lCLM,PLMnoAp,CLMnoAp] = miniCOMBOmasterPlanForPLM(rdsEMG,ldsEMG,...
        rlowThreshold,llowThreshold,rlowThreshold+6,llowThreshold+6,0.5,0.5,...
        in.fs,in.maxdur,epochStage,30,in.maxIMI,3,ApneaData,ArousalData,...
        HypnogramStart,in.lb1,in.ub1,in.lb2,in.ub2,doMed);
end

% Calculate PLMt: PLM with minimum IMI requirement (WASM standard is 5)
[PLMt] = minimasterPlanForPLMt(CLM,in.minIMI,in.fs,in.maxIMI,3);

PLMSt = PLMt(PLMt(:,6) > 0,:);

ldsEMG(:,2:4) = nan(length(ldsEMG),3); rdsEMG(:,2:4) = nan(length(rdsEMG),3);

% Mark lLM,rLM and PLM on respective dsEMG matrices
for i = 1:size(lCLM,1)
    ldsEMG(lCLM(i,1):lCLM(i,2),2) = 4;
end

for i = 1:size(rCLM,1)
    rdsEMG(rCLM(i,1):rCLM(i,2),2) = 4;
end

for i = 1:size(PLMSt,1)
    ldsEMG(PLMSt(i,1):PLMSt(i,2),3) = 6;
    rdsEMG(PLMSt(i,1):PLMSt(i,2),3) = 6;
end

% Calculate median removal for comparison
mlLM = cutLowMedian(ldsEMG,lCLM,2,500);
mrLM = cutLowMedian(rdsEMG,rCLM,2,500);

for i = 1:size(mlLM,1)
    ldsEMG(mlLM(i,1):mlLM(i,2),4) = 4;
end

for i = 1:size(mrLM,1)
    rdsEMG(mrLM(i,1):mrLM(i,2),4) = 4;
end

end