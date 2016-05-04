function [newPLM]=PLMApnea(PLM,ApneaData,HypnogramStart,lb,ub,fs)
%PLMApnea adds Apnea Events to the 11th col of the PLM Matrix if there is a PLM within -lb,+ub seconds of the event endpoint
%ApneaData is the CISRE_Apnea matrix
%HypnogramStart is the first data point

%% Form newAp, which is ApneaData with endpoint of event (in datapoints) added to 4th col
% This is calculated with HypnogramStart as datapoint 1
if size(ApneaData,1) == 0 || sum(ApneaData{1,1}) == 0
    newPLM=PLM;
    newPLM(:,11)=0;
    return
end

newAp=ApneaData;
[nrowsAp,ncolsAp]=size(ApneaData);
for ii=1:nrowsAp
   newAp{ii,4}=fs*etime(datevec(newAp{ii,1},'yyyy-mm-dd HH:MM:SS'),datevec(HypnogramStart,'yyyy-mm-dd HH:MM:SS'))+fs*str2num(ApneaData{ii,3})+1;   
end
%% Form newPLM, which is PLM with Apnea events in the 11th col
[nrowsPLM,ncolsPLM]=size(PLM);
newPLM=PLM;
for ii=1:nrowsAp
    for jj=1:nrowsPLM
        %If 'lb' seconds before the apnea endpoint is within the PLM interval,
        %or if 'ub' seconds after the endpoint is within the PLM interval
        %or if the PLM interval is within the apnea interval
        if(newAp{ii,4}-fs*lb>= PLM(jj,1) && newAp{ii,4}-fs*lb<=PLM(jj,2))||...
                (newAp{ii,4}+fs*ub>= PLM(jj,1) && newAp{ii,4}+fs*ub<=PLM(jj,2)) ||...
                (newAp{ii,4}-fs*lb<= PLM(jj,1) && newAp{ii,4}+fs*ub>= PLM(jj,2))
            switch newAp{ii,2}
                case 'APNEA'
                    newPLM(jj,11)=1;
                case 'APNEA-CENTRAL'
                    newPLM(jj,11)=2;
                case 'APNEA-MIXED'
                    newPLM(jj,11)=3;
                case 'APNEA-OBSTRUCTIVE'
                    newPLM(jj,11)=4;
                case 'DESAT'
                    newPLM(jj,11)=5;
                case 'HYPOPNEA'
                    newPLM(jj,11)=6;
                case 'HYPOPNEA-CENTRAL'
                    newPLM(jj,11)=7;
                case 'HYPOPNEA-MIXED'
                    newPLM(jj,11)=8;
                case 'HYPOPNEA-OBSTRUCTIVE'
                    newPLM(jj,11)=9;
                case 'PEDIATRIC-RESP-BASELINE'
                    newPLM(jj,11)=10;
                case 'RESP-MOVEMENT-STOP'
                    newPLM(jj,11)=11;
                case 'SNORE'
                    newPLM(jj,11)=12;
                otherwise
                    newPLM(jj,11) = 0;
            end
        end
    end
end
    