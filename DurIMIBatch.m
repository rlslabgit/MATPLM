[f p filt] = uigetfile('*.mat','MultiSelect','on');

dirlength = size(f,2);

data = cell(dirlength+1,11);
data(1,1) = {'Patient ID'};
data(1,2) = {'CLMwDur<2.5'};
data(1,3) = {'CLMwDur<2.5/hr'};
data(1,4) = {'CLMsDur<2.5'};
data(1,5) = {'CLMsDur<2.5/hr'};
data(1,6) = {'CLMIMIw<10'};
data(1,7) = {'CLMIMIw<10/hr'};
data(1,8) = {'CLMIMIs<10'};
data(1,9) = {'CLMIMIs<10/hr'};
data(1,10) = {'CLMw/hr'};
data(1,11) = {'CLMs/hr'};


for i=1:dirlength
    load([p f{1,i}],'CLM', 'epochStage');
    TST = (30*size(epochStage>0,1))/60;
    TWT = (30*size(epochStage==0,1))/60;
    CLMW = CLM(CLM(:,6)==0,:);
    CLMS = CLM(CLM(:,6)>0,:);
    data(i+1,1) = {f{1,i}(1:11)};
    data(i+1,2) = {size(CLMW(CLMW(:,3)<2.5,3),1)};
    data(i+1,3) = {size(CLMW(CLMW(:,3)<2.5,3),1)/TWT*60};
    data(i+1,4) = {size(CLMS(CLMS(:,3)<2.5,3),1)};
    data(i+1,5) = {size(CLMS(CLMS(:,3)<2.5,3),1)/TST*60};
    data(i+1,6) = {size(CLMW(CLMW(:,4)<10,4),1)};
    data(i+1,7) = {size(CLMW(CLMW(:,4)<10,4),1)/TWT*60};
    data(i+1,8) = {size(CLMS(CLMS(:,4)<10,4),1)};
    data(i+1,9) = {size(CLMS(CLMS(:,4)<10,4),1)/TST*60};
    data(i+1,10) = {size(CLMW,1)/TWT*60};
    data(i+1,11) = {size(CLMS,1)/TST*60};
end

clearvars -except data