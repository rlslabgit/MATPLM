function [LM,t] = new_indices_rev1(oEMG, params)

t = dt_rev1(oEMG,params.fs);

if params.ekg   
    [oEMG, re] = removeEKG_rev1(oEMG,params.fs,t(:,2));
%     if re
%         t = dt_rev1(oEMG,params.fs); % should recalculate (maybe don't have to)
%     end
end

% if they want a static threshold, just take the most common
if ~params.thresh
   m = mode(t(:,1));
   t(:,2) = m + 2; t(:,3) = m + 8;
end

LM = findIndices(oEMG(:,1), t(:,2), t(:,3), 0.5, 0.5, params.fs);
LM = cutLowMedian_rev2(LM, oEMG, params.fs, t);