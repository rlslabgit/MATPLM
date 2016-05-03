function CLM = combined_candidates(rLM,lLM,epochStage,apd,ard,hgs,params)

% Combine left and right and sort.
CLM = rOV(lLM,rLM,params.fs);

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
    
    % add breakpoints if IMI < minIMI. This is according to new standards
    if params.inlm
        CLM(CLM(:,4) < params.minIMI, 9) = 1;   
    end
    
    % The area of the leg movement should go here. However, it is not
    % currently well defined in the literature for combined legs, and we
    % have omitted it temporarily
    CLM(:,10) = 0;
               
    % Add apnea events (col 11) and arousal events (col 12)
    CLM = PLMApnea(CLM,apd,hgs,params.lb1,params.ub1,params.fs);
    CLM = PLMArousal(CLM,ard,hgs,params.lb2,params.ub2,params.fs);
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
            if next_too >= max_num
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
if ~isempty(CLM)
    CLM(:,13) = CLM(:,3); CLM(:,3) = 0;
end

end



% Old remove-overlap function, should be deleted
function [filteredLM] = rOV2(combinedLM,fs)

% First and second movement indeces.
i = 1;
j = 2;

% Index in new array.
newIdx = 1;

% Instantiate an array that is the size of the total combined LM.
arrLength = size(combinedLM,1);
filteredLM = zeros(arrLength,size(combinedLM,2));

while (i < arrLength)
    % Isolated movement with no overlap.
    if (combinedLM(i,2) < (combinedLM(j,1) - fs/2))
        filteredLM(newIdx,1) = combinedLM(i,1);
        filteredLM(newIdx,2) = combinedLM(i,2);
        filteredLM(newIdx,13) = combinedLM(i,13);
        i = i+1;
        j = j+1;
        newIdx = newIdx + 1;
        % Movement begins on one leg and continues on the other.
    elseif (combinedLM(i,2) > (combinedLM(j,1) - fs/2) && combinedLM(i,2) < combinedLM(j,2))
        filteredLM(newIdx,1) = combinedLM(i,1);
        
        while (combinedLM(i,2) > (combinedLM(j,1) - fs/2) && j < arrLength)
            i = i + 1; j = j + 1;
        end
        
        filteredLM(newIdx,2) = combinedLM(i,2);
        filteredLM(newIdx,13) = 3;
        i = i+1;
        j = j+1;
        newIdx = newIdx + 1;
        % Strange case where movements end at same time...
    elseif (combinedLM(i,2) == combinedLM(j,2))
        filteredLM(newIdx,1) = combinedLM(i,1);
        filteredLM(newIdx,2) = combinedLM(i,2);
        filteredLM(newIdx,13) = 3;
        
        i = i+1;
        j = j+1;
        % Movement occurs within a longer movement.
    else
        while (combinedLM(j,2) < combinedLM(i,2) && j < arrLength) % While end is within first LM
            j = j+1;
        end
        filteredLM(newIdx,1) = combinedLM(i,1);
        if (combinedLM(j,1) < combinedLM(i,2) && combinedLM(j,2) > combinedLM(i,2))
            filteredLM(newIdx,2) = combinedLM(j,2);
        else
            filteredLM(newIdx,2) = combinedLM(i,2);
        end
        filteredLM(newIdx,13) = 3;
        i = j;
        j = j+1;
        newIdx = newIdx + 1;
    end
end

% Remove trailing zeroes
filteredLM(all(filteredLM==0,2),:)=[];

end