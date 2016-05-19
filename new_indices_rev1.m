function LM = new_indices_rev1(oEMG, EKG, fs)

oEMG = removeEKG(oEMG, EKG, 500);

t = dt(oEMG,fs);
LM = findIndices(oEMG(:,1),t+2,t+8,0.5,0.5,500);

