function LM = findIndices_rev1(EMG,lT,hT,minlow,minhigh,fs)
%% LM = findIndices_rev1(EMG,lT,hT,minlow,minhigh,fs)
% This is easier to understand than findIndices, and possibly more
% versatile, but unless I find a really good reason to use it, findIndices
% is much, much faster (0.35 s vs 7 s)
LM = [];
i = 1;
finished = false;

while i < size(EMG,1)
    
    % State 0: no high run yet
    while EMG(i) < hT && ~finished
        inc_i;
    end
    inc_i;
    
    % State 1: detected high value
    push_low = 0;
    while push_low < fs * minhigh && ~finished
        if EMG(i) >= lT
            push_low = 0; inc_i;
        else
            push_low = push_low + 1; inc_i;
        end
    end
end
    

    function inc_i()
        if i < size(EMG, 1)
            i = i + 1;
        else
            % this is where the code is completed: we'll finish executing
            % the large while loop, but won't enter any of the subloops
            finished = true;
        end
    end
    
    
end