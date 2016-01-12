%% markPLM3 places a 1 in column 5 for all movements that are part of a run
%  of PLM.

function CLM = markPLM3(CLM,BPloc,fs)

bpPLM = BPloc(BPloc(:,3) == 1,:);

for i = 1:size(bpPLM,1)
    CLM(bpPLM(i,1):bpPLM(i,1) + bpPLM(i,2) - 1,5) = 1;
end

CLM=getIMI(CLM,fs); %Requires array same before and after =, gets IMI in number of data points
end