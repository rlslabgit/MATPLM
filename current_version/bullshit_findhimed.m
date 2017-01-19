function X = bullshit_findhimed(LM,EMG,t)

fs = 500;

X = array2table(LM);
X.best = zeros(size(X,1),1);

for i = 1:size(LM,1)
    win = 0.1; stop = false;
    while win < 1.3 && ~stop
        smoothed = medfilt1(EMG(LM(i,1):LM(i,2),1),round(win*fs)+1);
        
        if sum(smoothed >= t(LM(i,1):LM(i,2),2)) > 0
           X.best(i) = win;
        else
            stop = true;
        end
        
        win = win + 0.1;
    end
    
    
    
    
end


end