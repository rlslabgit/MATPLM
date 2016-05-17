function [PLMt,CLMt] = periodic_lms(CLM,params)
%% [PLMt,CLMt] = periodic_lms(CLM,params)
%  find period leg movements from the array of CLM. In the future, CLMt
%  will not remove any movements, but will just add breakpoints when IMI is
%  too short, duration is too long, etc.
%
%  TODO: add support for the intervening LM stuff

% Create CLMt array of all CLM with IMI greater than the minimum allowable
% if intervening lm option is not selected, we remove CLMs whose IMI are
% too short. Really, new standards say that these should always be
% breakpoint, so the first case is only for posterity.
if ~params.inlm
    CLMt = removeShortIMI(CLM,params.minIMI,params.fs);
    CLMt = getIMI(CLMt,params.fs);
else
    CLMt = CLM;
end
        
CLMt(:,5) = 0; % Restart PLM

BPloct = BPlocAndRunsArray(CLMt,params.minNumIMI);
CLMt = markPLM3(CLMt,BPloct,params.fs);

PLMt = CLMt(CLMt(:,5) == 1,:);

end
