function [newPLM]=PLMArousal_Patrick(PLM,ArousalData,HypnogramStart,lb,ub,fs)
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

startnum = datenum(HypnogramStart(1:19));
startnum = startnum + str2double(HypnogramStart(21:22))/100/3600/24;

for ii=1:nrowsAr
    starttime = datenum(newAr{ii,1}(1:19)); % fraction of a day
    starttime = starttime + str2double(newAr{ii,1}(21:22))/100/3600/24; % add centiseconds
    starttime = (starttime - startnum)*24*3600; % time since start of record in seconds
    
    % End time is start time + duration, multiplied by sampling rate to
    % give number of points since start of apnea event
    newAr{ii,4} = floor((starttime + str2double(ArousalData{ii,3}))*500);
    
           
end
%% Form newPLM, which is PLM with Arousal events in the 12th col
[nrowsPLM,ncolsPLM]=size(PLM);
newPLM=PLM ;
for ii=1:nrowsAr
    for jj=1:nrowsPLM
        %If 'lb' seconds before the arousal endpoint is within the PLM interval,
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
    