function CLM = combined_candidates(rLM,lLM,epochStage,apd,ard,hgs,params)

rLM(:,3) = (rLM(:,2)- rLM(:,1)) / params.fs;
lLM(:,3) = (lLM(:,2)- lLM(:,1)) / params.fs;

% Combine left and right and sort.
rLM(:,13) = 1; lLM(:,13) = 2;
combLM = [rLM;lLM];
combLM = sortrows(combLM,1);
CLM = rOV(combLM,params.fs);

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







% Identical to removeOverlap function in main folder...I assume this can be
% substantially improved.
function [filteredLM] = rOV(combinedLM,fs)

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