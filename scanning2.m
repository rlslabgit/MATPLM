% Scans dsEMG data in 10 second intervals, beginning at 0,1000,...,4000,
% then taking the median of those five values.
function [lowThresh,x] = scanning2(data,fs)

    x = zeros(5,1);
    datalen = size(data,1);

    for n = 0:4
        start = 0 + n*2*fs;
        stop = start + 10*fs;
        [maxSpike,maxAllow] = searchForThreshold(data,start,stop);
        while (maxSpike > 20 || maxSpike > maxAllow)
            start = stop;
            stop =  start + 10*fs;
            if stop < datalen
                [maxSpike,maxAllow] = searchForThreshold(data,start,stop);
            else
                maxSpike = -99;
            end
        end
        x(n+1,1) = maxSpike;
    end

    x(x==-99)=[];

    % In rare cases where the condition is never met, max out at 20
    if isempty(x)
        lowThresh = 20;
    else
        lowThresh = ceil(median(x))+2;
    end


end

%% Determines the maximum spike in a section of dsEMG, and the maximum 
%  allowable voltage for this section to represent the lower bound.
function [maxSpike,maxAllow] = searchForThreshold(data,start,stop)

    avg = mean(data(start+1:stop));
    st = std(data(start+1:stop));
    maxSpike = max(data(start+1:stop));

    maxAllow = avg + st*5; % temporary constant

    if min(data(start+1:stop)) <= 0
        maxAllow = -99;
    end

end