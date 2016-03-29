function [CLM] = removeOverlap(lLM,rLM,fs)
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
for i = 1:size(combLM(:,4),1)
    % If the last movement was combined, skip this one (it's already part
    % of it!)
    if i > 1 
        if combLM(i-1,4) == 1
            continue
        end
    end
    
    % if there is overlap
    if combLM(i,4) == 1
        next_too = 1;
        
        % allow up to max_num movements to combine
        for ii = 1:(max_num - 1)
            if combLM(i + next_too) == 1
                next_too = next_too + 1;
            end
            
            % if more than max_num, just leave
            if next_too >= max_num || 
                continue
            end
        end
        CLM = [CLM ; [combLM(i,1), combLM(i+next_too,2), 3]];
    
    % else, we're just a lonely unilateral mvmt. keep us
    else
        CLM = [CLM ; combLM(i,[1:2,5])];
    end
end

% move the leg indicator to the 13th column (out of the way of other values
CLM(:,13) = CLM(:,3); CLM(:,3) = 0;

end