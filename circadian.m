function [ cycle, circMeasure ] = circadian( PLMSt, T, fs,TRT )
%   T = cycle length in minutes
%   circadian
%   the cycle array has the number of PLM in that cycle, and the number of
%   PLM per hour 
start = PLMSt(:,1);
T = T*60*fs; %conversion from mins to data pts
index = 1; %index of cycle
cycleStart = 1;
cycleEnd = T;
while cycleEnd < TRT*60*fs  %PLMSt(size(PLMSt, 1), 1)
    cycle{index,1} = PLMSt(find(PLMSt(:,1) < cycleEnd & PLMSt(:,1)>=cycleStart), 1);
    cycle{index,2} = size(cycle{index,1}, 1);
    cycle{index,3} = cycle{index,2}/(T/3600/fs);
    cycleEnd = cycleEnd + T;
    cycleStart = cycleStart + T;
    
%     if cycleEnd >= PLMSt(size(PLMSt, 1), 1)
%         cycle{index+1,1} = PLMSt(find(PLMSt(:,1) < cycleEnd & PLMSt(:,1)>=cycleStart), 1);
%         cycle{index+1,2} = size(cycle{index+1,1}, 1);
%         cycle{index+1,3} = cycle{index+1,2}/(T/3600/fs);
%     end
    index = index + 1;      
end

% (number of PLMS in cycle * cycle number)/ total number of cycles 
circMeasure = 0;
totalcycles = size(cycle, 1);
for i = 1:size(cycle, 1)
    if mod(totalcycles,2)==0
        if i<=totalcycles/2
            cyclenumber = (i - totalcycles/2 -1 );
        else
            cyclenumber=i-totalcycles/2;
        end
    else
        cyclenumber = (i - ceil(totalcycles/2));
    end
    cyclenumber = cyclenumber / floor(totalcycles/2);
    numPLMsincycle = cycle{i,2};
    totalnumPLMS= sum(cell2mat(cycle(:,2)));
    circMeasure = circMeasure + (numPLMsincycle * cyclenumber)/ totalnumPLMS;
end 


end

