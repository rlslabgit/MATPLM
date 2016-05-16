% Modified by Patrick 5/5 to streamline code and avoid dangerous hardcoded
% fixes. This now correctly handles fractional seconds!


function [newPLM,h] = PLMApnea_rev2(PLM,ApneaData,HypnogramStart,lb,ub,fs)
%% [newPLM] = PLMApnea_Patrick(PLM,ApneaData,HypnogramStart,lb,ub,fs)
% PLMApnea adds Apnea Events to the 11th col of the PLM Matrix if there is
% a PLM within -lb,+ub seconds of the event endpoint
% ApneaData is the CISRE_Apnea matrix
% HypnogramStart is the first data point

% Form newAp, which is ApneaData with endpoint of event (in datapoints) 
% added to 4th col. This is calculated with HypnogramStart as datapoint 1

% There seem to be inconsistencies with how records without apnea or
% arousal data are coded. Sometimes it is a 1 x 3 vector of zeros, other
% times it is a 0 x 3 array (I don't even know what that means). We have to
% check for both, apparently.
if size(ApneaData, 1) == 0
    newPLM = PLM;
    newPLM(1,11) = 0;
    return
end
    
if ApneaData{1,1} == 0
    newPLM = PLM;
    newPLM(1,11) = 0;
    return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% start
ap_ends = zeros(size(ApneaData,1),1);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% start
start_vec = datevec(HypnogramStart);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% end

for ii = 1:size(ApneaData,1)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% start
    ap_start = datevec(ApneaData{ii,1});
    ap_ends(ii) = (etime(ap_start,start_vec) + ...
        str2double(ApneaData{ii,3})) * fs + 1;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% end    
end


% Form newPLM, which is PLM with Apnea events in the 11th col. These exact
% naming conventions are those output by Remlogic, and some conversion may
% be necessary from other sleep software.
newPLM=PLM;

for ii = 1:size(ApneaData, 1)
    for jj = 1:size(PLM, 1)
        %If 'lb' seconds before the apnea endpoint is within the PLM interval,
        %or if 'ub' seconds after the endpoint is within the PLM interval
        %or if the PLM interval is within the apnea interval
        if(ap_ends(ii) - fs*lb >= PLM(jj,1) && ap_ends(ii) - fs*lb <= PLM(jj,2)) ||...
                (ap_ends(ii) + fs*ub >= PLM(jj,1) && ap_ends(ii) + fs*ub <= PLM(jj,2)) ||...
                (ap_ends(ii) - fs*lb <= PLM(jj,1) && ap_ends(ii) + fs*ub >= PLM(jj,2))
            
            switch ApneaData{ii,2}
                case 'APNEA'
                    newPLM(jj,11) = 1;
                case 'APNEA-CENTRAL'
                    newPLM(jj,11) = 2;
                case 'APNEA-MIXED'
                    newPLM(jj,11) = 3;
                case 'APNEA-OBSTRUCTIVE'
                    newPLM(jj,11) = 4;
                case 'DESAT'
                    newPLM(jj,11) = 5;
                case 'HYPOPNEA'
                    newPLM(jj,11) = 6;
                case 'HYPOPNEA-CENTRAL'
                    newPLM(jj,11) = 7;
                case 'HYPOPNEA-MIXED'
                    newPLM(jj,11) = 8;
                case 'HYPOPNEA-OBSTRUCTIVE'
                    newPLM(jj,11) = 9;
                case 'PEDIATRIC-RESP-BASELINE'
                    newPLM(jj,11) = 10;
                case 'RESP-MOVEMENT-STOP'
                    newPLM(jj,11) = 11;
                case 'SNORE'
                    newPLM(jj,11) = 12;
                otherwise
                    newPLM(jj,11) = 0;
            end
        end
    end
end

h = ap_ends;
end
    