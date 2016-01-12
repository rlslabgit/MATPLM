                     %%remove PLMs with IMIs that are too short
                     %%adjusted to correct IMI after removal  as of 6Aug15
                     %%KH
                    

function CLMt = removeShortIMI(CLM,minIMIDuration,fs)
rc = 1;      
rowNum = size (CLM(:,4));
maxN = rowNum(1,1);  %% get the size of the array (number of rows)

for rl = 1:maxN;
    if CLM (rl,4) > minIMIDuration;   %% find any PLM that have duration greater than minPLMDuration from CLM and place it in the new array CLMt
       CLMt (rc,:) = CLM (rl,:);
       rc = rc +1;
    elseif rl<maxN
        CLM(rl+1,4)= CLM(rl+1,4)+CLM(rl,4);   %this adjusts the IMI to be from the previous movement to the next
    end
  
end

CLMt = getIMI (CLMt,fs);



end
