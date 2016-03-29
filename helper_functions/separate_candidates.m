function CLM = separate_candidates(LM,epochStage,apd,ard,hgs,params)
%% CLM = separate_candidates(LM,apd,ard,hgs,params)
%
% Use this file when you do not want to combine LAT and RAT channels for
% scoring. Identifies candidate leg movements by removing LMs that are too
% long, then fills in data in the table


LM(:,3) = (LM(:,2)- LM(:,1)) / params.fs;

% Candidates must have duration less than (default) 10 seconds if we are
% not combining two legs
CLM = LM(LM(:,3) < params.maxdur,:);

% If there are no CLM, return an empty vector
if ~isempty(CLM)
    % Add duration of leg movements (col 3), IMI (col 4), sleep stage (col
    % 6). Col 5 is reserved for PLM marks later
    CLM(:,3) = (CLM(:,2)-CLM(:,1))/params.fs;
    CLM = getIMI(CLM, params.fs);
    CLM(:,6) = epochStage(round(CLM(:,1)/30/params.fs+.5));
    
    % Add movement start time in minutes (col 7) and sleep epoch number
    % (col 8)
    CLM (:,7) = CLM(:,1)/(params.fs * 60);
    CLM (:,8) = round (CLM (:,7) * 2 + 0.5);
        
    % Mark movements (col 9) with breakpoints if they are preceeded by an
    % IMI > max allowable duration or have too long movement durations. There
    % also must be a breakpoint after a too long movement, so that a PLM run
    % does not begin on a movement > maxdur.
    % TODO: add breakpoints for intervening LM
    CLM(:,9) = CLM(:,4) > params.maxIMI | CLM(:,3) > params.maxdur;
    aftLong = find(CLM(:,3) > params.maxdur) + 1;
    aftLong = aftLong(aftLong < size(CLM,1));
    CLM(aftLong,9) = 1;
    
    % The area of the leg movement should go here. However, it is not
    % currently well defined in the literature for combined legs, and we
    % have omitted it temporarily
    CLM(:,10) = 0;
               
    % Add apnea events (col 11) and arousal events (col 12)
    CLM = PLMApnea(CLM,apd,hgs,params.lb1,params.ub1,params.fs);
    CLM = PLMArousal(CLM,ard,hgs,params.lb2,params.ub2,params.fs);
end

end
