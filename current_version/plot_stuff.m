function plot_stuff_rev1(rEMG, lEMG, plm_outputs, fs)

rLM = plm_outputs.rLM;
lLM = plm_outputs.lLM;
CLM = plm_outputs.CLM; % may want to see all PLMs
PLM = plm_outputs.PLM;

rEMG(:,2:4) = nan; lEMG(:,2:4) = nan;

% for i = 1:size(rLM,1)
%     rEMG(rLM(i,1):rLM(i,2),2) = rEMG(rLM(i,1):rLM(i,2),1);
% end
% 
% for i = 1:size(lLM,1)
%     lEMG(lLM(i,1):lLM(i,2),2) = lEMG(lLM(i,1):lLM(i,2),1);
% end

for i = 1:size(CLM,1)
    lEMG(CLM(i,1):CLM(i,2),2) = lEMG(CLM(i,1):CLM(i,2),1);
    rEMG(CLM(i,1):CLM(i,2),2) = rEMG(CLM(i,1):CLM(i,2),1);
end

% for i = 1:size(PLM,1)
%     lEMG(PLM(i,1):PLM(i,2),3) = lEMG(PLM(i,1):PLM(i,2),1);
%     rEMG(PLM(i,1):PLM(i,2),3) = rEMG(PLM(i,1):PLM(i,2),1);
% end

t = (1:size(lEMG))/fs/24/3600; t = t';
t = t + datenum(plm_outputs.hypnostart);

h(1) = subplot(2,1,1); reduce_plot(t,lEMG);
legend('none', 'mLM', 'PLM', 'CLM');
datetickzoom('x','HH:MM:SS');
h(2) = subplot(2,1,2); reduce_plot(t,rEMG);
legend('none', 'mLM', 'PLM', 'CLM');
linkaxes(h,'x'); datetickzoom('x','HH:MM:SS');


end



