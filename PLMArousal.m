function [newPLM]=PLMArousal(PLM,ArousalData,HypnogramStart,lb,ub,fs)
%PLMApnea adds Arousal Events to the 12th col of the PLM Matrix if there is a PLM within -lb,+ub seconds of the event endpoint
%ArousalData is the CISRE_Arousal matrix
%HypnogramStart is the first data point

if ArousalData{1,1}==0
	[nrowsPLM,ncolsPLM]=size(PLM);
    newPLM=PLM;
    newPLM(1,12)=0;
    return
end

%% Form newAr, which is ArousalData with endpoint of event (in datapoints) added to 4th col
% This is calculated with HypnogramStart as datapoint 1
newAr=ArousalData;
[nrowsAr,ncolsAr]=size(ArousalData);
for ii=1:nrowsAr
   newAr{ii,4}=fs*etime(datevec(newAr{ii,1},'yyyy-mm-dd HH:MM:SS'),datevec(HypnogramStart,'yyyy-mm-dd HH:MM:SS'))+fs*str2num(ArousalData{ii,3})+1;   
end
%% Form newPLM, which is PLM with Arousal events in the 12th col
[nrowsPLM,ncolsPLM]=size(PLM);
newPLM=PLM ;
for ii=1:nrowsAr
    for jj=1:nrowsPLM
        %If 'lb' seconds before the arousal  endpoint is within the PLM interval,
        %or if 'ub' seconds after the endpoint is within the PLM interval
        %or if the PLM interval is within the arousal interval
        if(newAr{ii,4}-fs*lb>= PLM(jj,1) && newAr{ii,4}-fs*lb<=PLM(jj,2))||(newAr{ii,4}+fs*ub>= PLM(jj,1) && newAr{ii,4}+fs*ub<=PLM(jj,2)) || (newAr{ii,4}-fs*lb<= PLM(jj,1) && newAr{ii,4}+fs*ub>= PLM(jj,2))
            switch newAr{ii,2}
                case 'AROUSAL'
                    newPLM(jj,12)=1;
                case 'AROUSAL-SPONT'
                    newPLM(jj,12)=2;
                case 'AROUSAL-LM'
                    newPLM(jj,12)=3;
                case 'AROUSAL-PLM'
                    newPLM(jj,12)=3;
                case 'AROUSAL-APNEA'
                    newPLM(jj,12)=4;
                case 'AROUSAL-DESAT'
                    newPLM(jj,12)=5;
                case 'AROUSAL-HYPOPNEA'
                    newPLM(jj,12)=6;
                case 'AROUSAL-RERA'
                    newPLM(jj,12)=7;
                case 'AROUSAL-RESP'
                    newPLM(jj,12)=8;
                case 'AROUSAL-SNORE'
                    newPLM(jj,12)=9;
      
            end
        end
    end
end
    