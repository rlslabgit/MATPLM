function CLM = candidate_lms_rev1(rLM,lLM,epochStage,apd,ard,hgs,params)

% Reduce left and right LM arrays to exclude too long movements, but add
% breakpoints to the following movement
rLM(find(rLM(:,3) > params.maxdur) + 1, 9) = 1;
rLM(rLM(:,3) > params.maxdur, :) = [];
lLM(find(lLM(:,3) > params.maxdur) + 1, 9) = 1;
lLM(lLM(:,3) > params.maxdur, :) = [];

% Combine left and right and sort.
CLM = rOV2(lLM,rLM,params.fs);
CLM(:,3) = (CLM(:,2) - CLM(:,1))/params.fs;

% add breakpoints if the duration of the combined movement is greater
% than 15 seconds (standard) or if a bilateral movement is made up of
% greater than 4 (standard) monolateral movements. These breakpoints
% are actually added to the subsequent movement, and the un-CLM is
% removed.
CLM(find(CLM(1:end-1,4) > params.maxcomb |...
    CLM(1:end-1,3) > params.bmaxdur)+1,9) = 1;
CLM(CLM(1:end,4) > params.maxcomb |...
    CLM(1:end,3) > params.bmaxdur,:) = [];

CLM(:,4) = 0; % clear out the #combined mCLM

% If there are no CLM, return an empty vector
if ~isempty(CLM)
    % Add IMI (col 4), sleep stage (col
    % 6). Col 5 is reserved for PLM marks later
    CLM = getIMI(CLM, params.fs);
    
    % add breakpoints if IMI > 90 seconds (standard)
    CLM(CLM(:,4) > params.maxIMI,9) = 1;
    % add breakpoints if IMI < minIMI. This is according to new standards
    if params.inlm
        CLM(CLM(:,4) < params.minIMI, 9) = 1;   
    end
    
    if ~isempty(epochStage)
        CLM(:,6) = epochStage(round(CLM(:,1)/30/params.fs+.5));
    end
    
    % Add movement start time in minutes (col 7) and sleep epoch number
    % (col 8)
    CLM (:,7) = CLM(:,1)/(params.fs * 60);
    CLM (:,8) = round (CLM (:,7) * 2 + 0.5);
    
    % The area of the leg movement should go here. However, it is not
    % currently well defined in the literature for combined legs, and we
    % have omitted it temporarily
    CLM(:,10) = 0;
    
    % Add apnea events (col 11) and arousal events (col 12)
    if ~isempty(apd) && ~isempty(hgs)
        CLM = PLMApnea_rev2(CLM,apd,hgs,params.lb1,params.ub1,params.fs);
    end
    if ~isempty(ard) && ~isempty(hgs)
        CLM = PLMArousal_rev2(CLM,ard,hgs,params.lb2,params.ub2,params.fs);
    end
end

end

function [CLM] = rOV2(lLM,rLM,fs)
%% REMOVEOVERLAP combine left and right leg LMs

% combine and sort LM arrays
rLM(:,13) = 1; lLM(:,13) = 2;
combLM = [rLM;lLM];
combLM = sortrows(combLM,1);

% distance to next movement
CLM = combLM;
CLM(:,4) = 1;

i = 1;

while i < size(CLM,1)
    % make sure to check if this is correct logic for the half second
    % overlap period...
    if isempty(intersect(CLM(i,1):CLM(i,2),(CLM(i+1,1)-fs/2):CLM(i+1,2)))
        i = i+1;
    else
        CLM(i,2) = max(CLM(i,2),CLM(i+1,2));
        CLM(i,4) = CLM(i,4) + CLM(i+1,4);
        CLM(i,9) = CLM(i,9) | CLM(i+1,9);
        CLM(i,13) = 3;
        CLM(i+1,:) = [];
    end
end

end
