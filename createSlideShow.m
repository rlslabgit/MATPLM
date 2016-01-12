function createSlideShow

numslides = 200; % Total number of samples to output
bigdir = dir('C:\Users\Administrator\Documents\MedianTestWorkspaces\G*');
fig_handle = figure('Position',[100 200 750 400]);


%% Start new presentation
isOpen  = exportToPPTX();
if ~isempty(isOpen),
    % If PowerPoint already started, then close first and then open a new one
    exportToPPTX('close');
end

exportToPPTX('open','Shuffled Examples');

for i = 1:numslides/10 % We get four from each subject
    
    patNum = randi(size(bigdir,1));
    
    patientID = bigdir(patNum).name(1:11);
    load(['C:\Users\Administrator\Documents\MedianTestWorkspaces\' patientID '.mat'],'ldsEMG');    
    
    lLM = findIndices(ldsEMG,4,10,0.5,0.5,500);
%     rLM = findIndices(rdsEMG,4,10,0.5,0.5,500);
    
    % Get rid of the long ones
    lLM = lLM((lLM(:,2) - lLM(:,1))/500 < 10,:);
%     rLM = rLM((rLM(:,2) - rLM(:,1))/500 < 10,:);
    
    [goodlLM,badlLM] = giveLowMedian(ldsEMG,lLM,4);
%     [goodrLM,badrLM] = giveLowMedian(rdsEMG,rLM,4);
    
    %% This is where I have to plot everything
    ldsEMG(:,2:6) = nan(length(ldsEMG),5);  % rdsEMG(:,2:6) = nan(length(rdsEMG),5);
    ldsEMG = markupdsEMG(ldsEMG,goodlLM,badlLM);
%     rdsEMG = markupdsEMG(rdsEMG,goodrLM,badrLM);
        
    maketheSlide(ldsEMG,goodlLM{1,1},2,patientID,fig_handle)
    maketheSlide(ldsEMG,goodlLM{2,1},3,patientID,fig_handle)
    maketheSlide(ldsEMG,goodlLM{3,1},4,patientID,fig_handle)
    maketheSlide(ldsEMG,goodlLM{4,1},5,patientID,fig_handle)
    maketheSlide(ldsEMG,badlLM,6,patientID,fig_handle)
    
%     maketheSlide(rdsEMG,goodrLM{1,1},2,patientID,fig_handle)
%     maketheSlide(rdsEMG,goodrLM{2,1},3,patientID,fig_handle)
%     maketheSlide(rdsEMG,goodrLM{3,1},4,patientID,fig_handle)
%     maketheSlide(rdsEMG,goodrLM{4,1},5,patientID,fig_handle)
%     maketheSlide(rdsEMG,badrLM,6,patientID,fig_handle)
    
    exportToPPTX('save');
    
    clearvars -except fig_handle i numslides bigdir patNum
end


end

function dsEMG = markupdsEMG(dsEMG,goodLM,badLM)

% The best: 1 sec of median above threshold (2nd col)
for i = 1:size(goodLM{1,1},1)
    dsEMG(goodLM{1,1}(i,1):goodLM{1,1}(i,2),2) = 4;
end

% Next best: 0.75 sec (3rd col)
for i = 1:size(goodLM{2,1},1)
    dsEMG(goodLM{2,1}(i,1):goodLM{2,1}(i,2),3) = 4;
end

% Third best: 0.5 sec (4th col)
for i = 1:size(goodLM{3,1},1)
    dsEMG(goodLM{3,1}(i,1):goodLM{3,1}(i,2),4) = 4;
end

% Fourth best: 0.25 sec (5th col)
for i = 1:size(goodLM{4,1},1)
    dsEMG(goodLM{4,1}(i,1):goodLM{4,1}(i,2),5) = 4;
end

% The worst: No 0.25 sec at all (6th col)
for i = 1:size(badLM,1)
    dsEMG(badLM(i,1):badLM(i,2),6) = 4;
end
end


function maketheSlide(dsEMG,LM,des,patientID,fig_handle)
% dsEMG obviously comes from one leg or the other
% LM is one of the 5 possible (4 good, 1 bad) arrays for this leg
% des is 2:6, representing the column of dsEMG to plot
% patientID is just the string

if size(LM,1) > 0
    move = randi(size(LM,1)); % pick a random movement
    timebuff = round((5000 - LM(move,3))/2); % give us a 15 sec window
    
    s = LM(move,1)-timebuff; st = LM(move,2)+timebuff;
    t = (s:st)/500/24/3600;
    y = dsEMG(s:st,:);
    
    plot(t,y(:,1)); % The actual plot of the signal
    
    % Plot lines for lower and upper threshold and add ticks
%     v = get(gca);
%     lt = line([0 0 NaN v.XLim],[v.YLim NaN 4 4 ]);
%     set(lt,'Color',[238/256 238/256 238/256],'LineWidth',1);
%     ut = line([0 0 NaN v.XLim],[v.YLim NaN 10 10 ]);
%     set(ut,'Color',[238/256 238/256 238/256],'LineWidth',1);
    set(gca,'XTick',t(1):1/24/3600:t(end),'xgrid','on','Fontsize',8);    
    datetick('x','MM:SS','keepticks'); hold on;
    
       
    plot(t,y(:,des),'r-','LineWidth',4); hold off;
    axis([t(1) t(end) 0 50]);
    
    % Write left leg passing movements
    exportToPPTX('addslide');
    exportToPPTX('addpicture',fig_handle);
    savefig(['C:\Users\Administrator\Documents\Empty PLM Paper\Figures for Stephany\' patientID '_cat' num2str(des)]);
    
    switch des
        case 2 , exportToPPTX('addnote',sprintf(['t > 1 sec\n' patientID]));
        case 3 , exportToPPTX('addnote',sprintf(['0.75 < t < 1 sec\n' patientID]));
        case 4 , exportToPPTX('addnote',sprintf(['0.5 < t < 0.75 sec\n' patientID]));
        case 5 , exportToPPTX('addnote',sprintf(['0.25 < t < 0.5 sec\n' patientID]));
        case 6 , exportToPPTX('addnote',sprintf(['t < 0.25 sec (emptiest)\n' patientID]));
    end
    clf(fig_handle);
end

end
