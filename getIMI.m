%% getIMI calculates intermovement interval and stores in the fourth column
%  of the input array. IMI is onset-to-onset and measured in seconds
function LM = getIMI(LM,fs) 

LM(1,4) = 9999; % archaic... don't know if we need this
LM(2:end,4) = (LM(2:end,1) - LM(1:end-1,1))/fs;


end
