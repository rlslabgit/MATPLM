function [CLM,CLMS,PLMS] = teeny1leg(dsEMG,epochStage)
%% Find leg movements in a single EMG channel
% [CLM,CLMS,PLMS] = teeny1leg(dsEMG,epochStage)
%
% Inputs:
%   dsEMG - filtered, rectified, dynamically adjusted!
%   epochStage - array of sleep stages, by epoch
%
% Outputs:
%   CLM - all candidate leg movements, activity density requirement
%    included
%   CLMS - only CLM in sleep
%   PLMS - periodic leg movements, IMI > minIMIduration sec

fs = 500;
minIMIduration = 5;

CLM = findIndices(dsEMG,4,10,0.5,0.5,fs);
CLM = cutLowMedian(dsEMG,CLM,2,fs);
CLM(:,3) = (CLM(:,2)-CLM(:,1))/fs;
CLM = getIMI(CLM, fs);
% Column 5 is dumb
CLM(:,6) = epochStage(round(CLM(:,1)/30/fs+.5));
% There is really no reason for anything past the sixth column for now...

[PLM,~] = minimasterPlanForPLMt(CLM,minIMIduration,500,90,3,10);
PLMS = PLM(PLM(:,6) > 0,:);
CLMS = CLM(CLM(:,6) > 0,:);
end