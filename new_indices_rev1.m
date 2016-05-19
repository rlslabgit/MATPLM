function [LM,t] = new_indices_rev1(oEMG, fs)

t = dt(oEMG,fs);
oEMG = removeEKG_rev1(oEMG,500,t(:,2));

LM = findIndices(oEMG(:,1), t(:,2), t(:,3), 0.5, 0.5, fs);
LM = cutLowMedian_rev1(LM, oEMG, fs, t(:,2));