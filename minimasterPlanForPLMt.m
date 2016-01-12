%% minimasterPlanForPLMt select for only those movements with a minimum
%  intermovement interval to return PLMt (truncated)

function [PLMt,CLMt] = minimasterPlanForPLMt(CLM,minIMIDuration,fs,maxIMIDuration,minNumIMI,maxDuration)

% Create CLMt array of all CLM with IMI greater than the minimum allowable
CLMt = removeShortIMI(CLM,minIMIDuration,fs);
CLMt(:,5) = 0; CLMt(:,9) = 0; % Restart PLM and Breakpoints

% Recalculate IMI after removing those that are too short
CLMt = getIMI(CLMt,fs);

% Add break points where IMI > maxIMIDuration
CLMt(:,9) = CLMt(:,4) > maxIMIDuration | CLMt(:,3) > maxDuration;
aftLong = find(CLMt(:,3) > maxDuration) + 1;
aftLong = aftLong(aftLong < size(CLMt,1));
CLMt(aftLong,9) = 1;

BPloct = BPlocAndRunsArray(CLMt,minNumIMI);
CLMt = markPLM3(CLMt,BPloct,fs);

PLMt = CLMt(CLMt(:,5) == 1,:);

end
