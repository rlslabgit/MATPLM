function nLM = cutLowMedian_rev1(LM,EMG,fs,t)

nLM = LM * 0; j = 1;

for i = 1:size(LM,1)
    data = EMG(LM(i,1):LM(i,2),1);
    
    d = medfilt2(data,[fs/2,1]);
    d(:,2) = t(LM(i,1):LM(i,2));
    
    if sum(d(:,1) > d(:,2)) > 0
        % nLM = [nLM ; LM(i,:)];
        nLM(j,:) = LM(i,:);
        j = j+1;
    end
end

nLM = nLM(1:j-1,:);