function CLM = candidate_lms_rev1(rLM,lLM,epochStage,apd,ard,hgs,params)

if isempty(rLM)
    lLM(:,3) = (lLM(:,2) - lLM(:,1))/params.fs;
    CLM = lLM(lLM(:,3) < params.maxdur,:);
elseif isempty(lLM)
    rLM(:,3) = (rLM(:,2) - rLM(:,1))/params.fs;
    CLM = rLM(rLM(:,3) < params.maxdur,:);
else
    % Combine left and right and sort.
    CLM = rOV(lLM,rLM,params.fs);
end

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

    % The area of the leg movement should go here. However, it is not
    % currently well defined in the literature for combined legs, and we
    % have omitted it temporarily
    CLM(:,10) = 0;
               
    % Add apnea events (col 11) and arousal events (col 12)
    CLM = PLMApnea_rev2(CLM,apd,hgs,params.lb1,params.ub1,params.fs);
    CLM = PLMArousal_rev2(CLM,ard,hgs,params.lb2,params.ub2,params.fs);
end

end



function [CLM] = rOV(lLM,rLM,fs)
%% REMOVEOVERLAP combine left and right leg LMs

CLM = [];
max_num = 4; % the maximum allowable unilateral mvmts to make a bilateral

% combine and sort LM arrays
rLM(:,5) = 1; lLM(:,5) = 2;
combLM = [rLM;lLM];
combLM = sortrows(combLM,1);

% distance to next movement
combLM(1:end-1,3) = combLM(2:end,1) - combLM(1:end-1,2);
combLM(1:end-1,4) =  combLM(1:end-1,3) < fs/2;

% iterate through the combined rLM and lLM array
i = 1;
while i <= size(combLM,1)
    % If the last movement was combined, skip this one (it's already part
    % of it!)
    if i > 1 
        if combLM(i-1,4) == 1
            i = i+1;
            continue
        end
    end
    
    % if there is overlap
    if combLM(i,4) == 1
        next_too = 1;
        
        % allow up to max_num movements to combine
        for ii = 1:(max_num - 1)
            if combLM(i + next_too,4) == 1
                next_too = next_too + 1;
            end                        
        end
        % if more than max_num, just leave
        if next_too >= max_num
            i = i+next_too; % skip all of the combined movements
            continue
        end
        CLM = [CLM ; [combLM(i,1), combLM(i+next_too,2), 3]];
        i = i+next_too;
    % else, we're just a lonely unilateral mvmt. keep us
    else
        CLM = [CLM ; combLM(i,[1:2,5])];
        i = i+1;
    end
end

% move the leg indicator to the 13th column (out of the way of other values
if ~isempty(CLM)
    CLM(:,13) = CLM(:,3); CLM(:,3) = 0;
end

end
