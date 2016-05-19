function plot_stuff_rev1(rEMG, lEMG, plm_outputs)

rLM = plm_outputs.rLM;
lLM = plm_outputs.lLM;
PLMS = plm_outputs.PLMS; % may want to see all PLMs
PLM = plm_outputs.PLMS;

rEMG(:,2:4) = nan; lEMG(:,2:4) = nan;

for i = 1:size(rLM,1)
    rEMG(rLM(i,1):rLM(i,2),2) = rEMG(rLM(i,1):rLM(i,2),1);
end

for i = 1:size(lLM,1)
    lEMG(lLM(i,1):lLM(i,2),2) = lEMG(lLM(i,1):lLM(i,2),1);
end

for i = 1:size(PLMS,1)
    lEMG(PLMS(i,1):PLMS(i,2),4) = lEMG(PLMS(i,1):PLMS(i,2),1);
    rEMG(PLMS(i,1):PLMS(i,2),4) = rEMG(PLMS(i,1):PLMS(i,2),1);
end

for i = 1:size(PLM,1)
    lEMG(PLM(i,1):PLM(i,2),3) = lEMG(PLM(i,1):PLM(i,2),1);
    rEMG(PLM(i,1):PLM(i,2),3) = rEMG(PLM(i,1):PLM(i,2),1);
end

h(1) = subplot(2,1,1); reduce_plot(lEMG);
h(2) = subplot(2,1,2); reduce_plot(rEMG);
linkaxes(h,'x');