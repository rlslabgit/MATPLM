% WARNING: This is a really terrible program. It does the bare minimum and
% has poor documentation. Created 11/13 to get each leg seperately for
% RestEaze validation. Does no error handling, so should not be used for
% batch processing f

function [rCLMS,rPLMS,rdsEMG,lCLMS,lPLMS,ldsEMG,sleepRecordStart,sleepRecordEnd] = teenyfullRun(StructName)

for i = 1:size(StructName.Signals,2)
    if strcmp(strtrim(StructName.Signals(i).label),'Left Leg')
        lidx = i;
    elseif strcmp(strtrim(StructName.Signals(i).label),'Right Leg')
        ridx = i;
    end
end
[lEMG] = StructName.Signals(lidx).data;
[rEMG] = StructName.Signals(ridx).data;
sleepRecordStart = StructName.EDFStart2HypnoInSec * 500 + 1;
sleepRecordEnd = sleepRecordStart + ...
   size(StructName.CISRE_Hypnogram, 1) * 30 * 500;
[epochStage] = StructName.CISRE_Hypnogram;
if sleepRecordEnd >= max(size(rEMG,1),size(lEMG,1))
    sleepRecordEnd = min(size(rEMG,1),size(lEMG,1)); 
end

if size(find(isnan(lEMG(sleepRecordStart:sleepRecordEnd)),1)) > 0, sleepRecordEnd = find(isnan(lEMG(sleepRecordStart:sleepRecordEnd)),1) - 1; end; 
if size(find(isnan(rEMG(sleepRecordStart:sleepRecordEnd)),1)) > 0, sleepRecordEnd = find(isnan(rEMG(sleepRecordStart:sleepRecordEnd)),1) - 1; end; 
[ldsEMG] = filterAnddsEMG(25,225,500,lEMG,sleepRecordStart,sleepRecordEnd);
[rdsEMG] = filterAnddsEMG(25,225,500,rEMG,sleepRecordStart,sleepRecordEnd);

nldsEMG = dynamicThreshold2(ldsEMG,500);
nrdsEMG = dynamicThreshold2(rdsEMG,500);

[rCLM,rCLMS,rPLMS] = teeny1leg(nrdsEMG,epochStage);
[lCLM,lCLMS,lPLMS] = teeny1leg(nldsEMG,epochStage);
end