% Plots dsEMG and overlays a green line where a leg movement occurs, and a
% red line when that leg movement is also periodic. 

function plotandmark(dsEMG,LM,PLM,fs,sleepStart,plotTitle)

reduce_plot((1+sleepStart:length(dsEMG)+sleepStart)/fs/24/3600,dsEMG,'b');
hold on;

lT = scanning2(dsEMG,fs);
hT = lT + 6;
l = plot([1+sleepStart,length(dsEMG)+sleepStart]/fs/24/3600,[lT,lT],'r:');
plot([1+sleepStart,length(dsEMG)+sleepStart]/fs/24/3600,[hT,hT],'r:');

% plot all leg movements first
for i=1:size(LM,1)
    lm = plot([LM(i,1)+sleepStart,LM(i,2)+sleepStart]/fs/24/3600,[hT,hT],'g-','LineWidth',5);
end

for i=1:size(PLM,1)
    plm = plot([PLM(i,1)+sleepStart,PLM(i,2)+sleepStart]/fs/24/3600,[hT+2,hT+2],'r-','LineWidth',5);
end

title(plotTitle);
xlabel('Recording time');
ylabel('Voltage (\muv)');
legend([l,lm,plm],'Threshold','Leg Movement','PLMS');
end