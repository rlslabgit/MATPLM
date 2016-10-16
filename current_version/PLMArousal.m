% Modified by Patrick 5/5 to streamline code and avoid dangerous hardcoded
% fixes. This now correctly handles fractional seconds!


function [newPLM,h] = PLMArousal(PLM,ArousalData,HypnogramStart,lb,ub,fs)
%% [newPLM] = PLMApnea_Patrick(PLM,ApneaData,HypnogramStart,lb,ub,fs)
% PLMApnea adds Apnea Events to the 11th col of the PLM Matrix if there is
% a PLM within -lb,+ub seconds of the event endpoint
% ApneaData is the CISRE_Apnea matrix
% HypnogramStart is the first data point

% Form newAp, which is ApneaData with endpoint of event (in datapoints) 
% added to 4th col. This is calculated with HypnogramStart as datapoint 1
if size(ArousalData,1) == 0
    newPLM = PLM;
    newPLM(1,12) = 0;
    return    
end
if ArousalData{1,1} == 0
    newPLM = PLM;
    newPLM(1,12) = 0;
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% start
ar_ends = zeros(size(ArousalData,1),1);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% start
start_vec = datevec(HypnogramStart);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% end

for ii = 1:size(ArousalData,1)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% start
    ar_start = datevec(ArousalData{ii,1});
    ar_ends(ii) = (etime(ar_start,start_vec) + ...
        str2double(ArousalData{ii,3})) * fs + 1;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% end    
end


% Form newPLM, which is PLM with Apnea events in the 11th col. These exact
% naming conventions are those output by Remlogic, and some conversion may
% be necessary from other sleep software.
newPLM=PLM;

for ii = 1:size(ArousalData, 1)
    for jj = 1:size(PLM, 1)
        %If 'lb' seconds before the apnea endpoint is within the PLM interval,
        %or if 'ub' seconds after the endpoint is within the PLM interval
        %or if the PLM interval is within the apnea interval
        if(ar_ends(ii) - fs*lb >= PLM(jj,1) && ar_ends(ii) - fs*lb <= PLM(jj,2)) ||...
                (ar_ends(ii) + fs*ub >= PLM(jj,1) && ar_ends(ii) + fs*ub <= PLM(jj,2)) ||...
                (ar_ends(ii) - fs*lb <= PLM(jj,1) && ar_ends(ii) + fs*ub >= PLM(jj,2))
            
            switch ArousalData{ii,2}
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
                otherwise
                    newPLM(jj,12) = 0;
            end
        end
    end
end

h = ar_ends;
end
    