%% Extract the PLMSt associated with arousals
function [PLMStArousal,PLMStArousalhr,PLMStI] = PLMStArousal (PLMSt,epochStage)

PLMStArousal = zeros(3,size(PLMSt,2));
rs = 1;
max = size(PLMSt);
max = max(1,1);

for rd = 1: max
    if PLMSt(rd,12)> 0
       PLMStArousal(rs,:) = PLMSt(rd,:);
       rs = rs +1;
    end
end

%% calculates PLMSt with arousal /total sleep time
TST = size(find(epochStage),1)/2;
TRT = size(epochStage,1)/2;

if PLMStArousal (1,1) ~=0
    num = size(PLMStArousal);
    num = num(1,1);
else num = 0;
end
PLMStArousalhr  = num / TST;

%% calculates the PLMSt with arousal / PLMSt

PLMStnum = size(PLMSt);
PLMStnum = PLMStnum(1,1);
PLMStI = num / PLMStnum;


end