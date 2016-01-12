%% Right now, it plots information that you give it (2 LM arrays and a PLM
% array), performing no calculations on its own. I just want this to plot
% right now, and trying to calculate things is too slow and inconsistent.

function ops = PlotStuff(dsEMG1,dsEMG2,varargin)

addpath('date ticks');
% At the very least, the function plots two dsEMG vectors as vertically
% arranged subplots. One or two LM arrays may be included as well, and will
% be indicated by green lines over their respective dsEMG. A PLM array may
% also be included, but periodic movements are defined bilaterally, so each
% subplot will overlay the same PLM plot. Finally, providing a HypnoStart
% in the format YYYY-MM-DD HH:MM:SS, but giving the time digits alone will
% suffice. 
%
% Varargin names are: LM1  LM2  PLM  HypnoStart

ops = struct('fs',500,'LM1',zeros(1,2),'LM2',zeros(1,2),'PLM',zeros(1,13),...
    'HypnoStart','00:00:00');
opNames = fieldnames(ops);

nArgs = length(varargin);
if round(nArgs/2) ~= nArgs/2
    error('Needs Name/Value pairs')
end

for pair = reshape(varargin,2,[])
    inpName = pair{1};

    if any(strcmp(inpName,opNames))
        if ~isempty(pair{2})
            ops.(inpName) = pair{2};
        end
    else
        error('%s is not a recognized parameter name',inpName')
    end
end

%%Get the start time in data points
[~,~,~,H,Mn,S] = datevec(ops.HypnoStart);
sleepStart = (H*3600+Mn*60+S)*500;

figure;

% Plot first data set and set time ticks
ha(1) = subplot(2,1,1);
plotandmark(dsEMG1,ops.LM1,ops.PLM,ops.fs,sleepStart,'dsEMG1');
datetick('x','HH:MM')
zoomAdaptiveDateTicks('on')

% Plot second data set and set time ticks
ha(2) = subplot(2,1,2);
plotandmark(dsEMG2,ops.LM2,ops.PLM,ops.fs,sleepStart,'dsEMG2');
datetick('x','HH:MM')
zoomAdaptiveDateTicks('on')

% Link x axes so that you look at both records concurrently. Y-axis should
% not be linked since there is no isometry with vertical axis.
linkaxes(ha, 'x');


% Plot a histogram of the inter-movement intervals. Routine automatically
% discounts 'too long' IMI, which is just hard coded at 90 seconds right
% now.
PLMSIMI = ops.PLM(ops.PLM(:,4) < 90,:);
figure; hist(log(PLMSIMI(:,4)),1000);
set(gca,'XTick',[log(1) log(2) log(5) log(10) log(20) log(50) log(90)]);
set(gca,'XTickLabel',[1 2 5 10 20 50 90]);
title('IMI Distribution');
ylabel('Number of PLM');
xlabel('IMI (sec)');

end