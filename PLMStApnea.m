%% Extract the PLMSt associated with apnea
function [PLMStApnea,PLMStApneahr,PLMStIApnea] = PLMStApnea (PLMSt,epochStage)

PLMStApnea = zeros(3,size(PLMSt,2));
rs = 1;
max = size(PLMSt);
max = max(1,1);

for rd = 1: max
    if PLMSt(rd,11)> 0
       PLMStApnea(rs,:) = PLMSt(rd,:);
       rs = rs +1;
    end
end

%% calculate PLMSt with apnea/ total sleep time
TST = size(find(epochStage),1)/2;
TRT = size(epochStage,1)/2;

if PLMStApnea (1,1) ~=0
    num = size(PLMStApnea);
    num = num(1,1);
else num = 0;
end
PLMStApneahr  = num / TST;

%% calculate the PLMSt with apnea / PLMSt

PLMStnum = size(PLMSt);
PLMStnum = PLMStnum(1,1);
PLMStIApnea = num / PLMStnum;


end