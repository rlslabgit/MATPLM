function [CLM] = bullshit_rOV(PLM,tPLM,fs)
%% Possible use for validation?

% combine and sort LM arrays
tPLM(:,3) = 1; PLM(:,3) = 2;
combLM = [tPLM;PLM];
combLM = sortrows(combLM,1);

% distance to next movement
CLM = combLM;

i = 1;

while i < size(CLM,1)
    if CLM(i,3) == CLM(i+1,3)
        i = i+1;    
    elseif isempty(intersect(CLM(i,1):CLM(i,2),(CLM(i+1,1)-fs*2):CLM(i+1,2)))
        i = i+1;
    else
        CLM(i,2) = max(CLM(i,2),CLM(i+1,2));        
        CLM(i,3) = 3;
        CLM(i+1,:) = [];
    end
end

end