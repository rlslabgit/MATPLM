function [PLMt,CLMt] = periodic_lms(CLM,params)
%% [PLMt,CLMt] = periodic_lms(CLM,params)
%  find period leg movements from the array of CLM. In the future, CLMt
%  will not remove any movements, but will just add breakpoints when IMI is
%  too short, duration is too long, etc.
%
%  TODO: add support for the intervening LM stuff

% Create CLMt array of all CLM with IMI greater than the minimum allowable
CLMt = removeShortIMI(CLM,params.minIMI,params.fs);
CLMt(:,5) = 0; CLMt(:,9) = 0; % Restart PLM and Breakpoints

% Recalculate IMI after removing those that are too short
CLMt = getIMI(CLMt,params.fs);

% Add break points where IMI > maxIMIDuration
CLMt(:,9) = CLMt(:,4) > params.maxIMI | CLMt(:,3) > params.maxdur;
aftLong = find(CLMt(:,3) > params.maxdur) + 1;
aftLong = aftLong(aftLong < size(CLMt,1));
CLMt(aftLong,9) = 1;

BPloct = BPlocAndRunsArray(CLMt,params.minNumIMI);
CLMt = markPLM3(CLMt,BPloct,params.fs);

PLMt = CLMt(CLMt(:,5) == 1,:);

end
