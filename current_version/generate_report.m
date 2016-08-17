function generate_report(plm_outputs, params)

ep = plm_outputs.epochstage;
TST = sum(ep > 0,1)/120; TWT = sum(ep == 0,1)/120; 

display(sprintf('Total sleep time: %.2f hours',TST));

PLMSi = size(plm_outputs.PLMS,1)/TST;
display(sprintf('PLMS index: %.2f per hour',PLMSi));

PLMWi = size(setdiff(plm_outputs.PLM,plm_outputs.PLMS,'rows'),1)/TWT;
display(sprintf('PLMW index: %.2f per hour', PLMWi));

PLMS_Ni = sum(plm_outputs.PLMS(:,6) < 5)/(sum(ep > 0 & ep < 5)/120);
display(sprintf('PLMS-N index: %.2f per hour',PLMS_Ni));

PLMS_Ri = sum(plm_outputs.PLMS(:,6) == 5)/(sum(ep == 5)/120);
display(sprintf('PLMS-R index: %.2f per hour',PLMS_Ri));

PLMS_ai = sum(plm_outputs.PLMS(:,12) > 0)/TST;
display(sprintf('PLMS-arousal index: %.2f per hour',PLMS_ai));

% Here we display PLMS/hr excluding CLM associated with apnea events. This
% requires a reevaluation of periodicity, but I am unsure whether
% apnea-associated CLM should be removed or breakpoints added. And I don't
% know if this needs to be done in candidate_lms or periodic_lms
% nrCLM = plm_outputs.CLM(plm_outputs.CLM(:,11) == 0,:);

% The next 3 displays are indices for CLM associated with apnea events
% (suppose I should say respiratory, since they're abbreviated rCLM)
rCLMSi = sum(plm_outputs.CLMS(:,11) > 0)/TST;
display(sprintf('rCLMS index: %.2f per hour',rCLMSi));

rCLMS_Ni = sum(plm_outputs.CLMS(:,11) > 0 & plm_outputs.CLMS(:,6) < 5)/...
    (sum(ep > 0 & ep < 5)/120);
display(sprintf('rCLMS-N index: %.2f per hour',rCLMS_Ni));

rCLMS_Ri = sum(plm_outputs.CLMS(:,11) > 0 & plm_outputs.CLMS(:,6) == 5)/...
    (sum(ep == 5)/120);
display(sprintf('rCLMS-R index: %.2f per hour',rCLMS_Ri));

% The next 2 displays are indices for CLM with IMI less than the min IMI
short_CLMSi = sum(plm_outputs.CLMS(:,4) < params.minIMI)/TST;
display(sprintf('short IMI CLMS index: %.2f per hour',short_CLMSi));

short_CLMWi = sum(plm_outputs.CLM(:,4) < params.minIMI & ...
    plm_outputs.CLM(:,6) == 0)/TWT;
display(sprintf('short IMI CLMW index: %.2f per hour',short_CLMWi));

% Next 2 dipslays are are nonperiodic CLM
np_CLMSi = sum(plm_outputs.CLMS(:,5) == 0)/TST;
display(sprintf('nonperiodic CLMS index: %.2f per hour',np_CLMSi))

np_CLMWi = sum(plm_outputs.CLM(:,5) == 0 & plm_outputs.CLM(:,6) == 0)/TWT;
display(sprintf('nonperiodic CLMW index: %.2f per hour',np_CLMWi))

% Next 4 are some duration stuff
PLMS_dur = mean(plm_outputs.PLMS(:,3));
display(sprintf('mean PLMS duration: %.2f s',PLMS_dur));

PLMS_Ndur = mean(plm_outputs.PLMS(plm_outputs.PLMS(:,6) < 5,3));
display(sprintf('mean PLMS-N duration: %.2f s',PLMS_Ndur));

PLMS_Rdur = mean(plm_outputs.PLMS(plm_outputs.PLMS(:,6) == 5,3));
display(sprintf('mean PLMS-R duration: %.2f s',PLMS_Rdur));

PLMW_dur = mean(plm_outputs.PLM(plm_outputs.PLM(:,6) == 0,3));
display(sprintf('mean PLMW-N duration: %.2f s',PLMW_dur));

% The next 2 displays are duration for CLM with IMI less than the min IMI
short_CLMSdur = mean(plm_outputs.CLMS(plm_outputs.CLMS(:,4) < params.minIMI,3));
display(sprintf('short IMI CLMS duratoin: %.2f s',short_CLMSdur));

short_CLMWdur = mean(plm_outputs.CLM(plm_outputs.CLM(:,4) < params.minIMI & ...
    plm_outputs.CLM(:,6) == 0,3));
display(sprintf('short IMI CLMW duration: %.2f s',short_CLMWdur));

right_mPLMSi = sum(plm_outputs.PLMS(:,13) == 1)/TST;
display(sprintf('right monolateral PLMS index: %.2f per hour',right_mPLMSi));

left_mPLMSi = sum(plm_outputs.PLMS(:,13) == 2)/TST;
display(sprintf('left monolateral PLMS index: %.2f per hour',left_mPLMSi));

bPLMSi = sum(plm_outputs.PLMS(:,13) == 3)/TST;
display(sprintf('bilateral PLMS index: %.2f per hour',bPLMSi));


end

