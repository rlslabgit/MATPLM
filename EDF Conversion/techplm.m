%function PLM = techplm()
% can be used for batch processing with a little work

f = 'D:\Glutamate Study\AidRLS, G59734_V1N2 - 1_30_2014\G59734_V1N2 AidRLS-Events PLM.txt';

T = readtable(f,'headerlines',15);
formatIn = 'yyyy-mm-ddTHH:MM:SS'; % original didn't have milliseconds

% WARNING: this is not the start time used for PSG analysis. Make sure we
% give these in the correct way.
starttime = T{1,1};

plms = find(strcmp(T.Var2,'PLM-LM'));

T = T(plms,:);

tPLM = zeros(size(T,1),2);
starttime = repmat(starttime,[size(T,1) 1]);
tPLM(:,1) = etime(datevec(T.Var1(:),formatIn),datevec(starttime(:,1),formatIn));
tPLM(:,1) = tPLM(:,1) * 500;
tPLM(:,2) = tPLM(:,1) + T.Var3(:)*500;

clear T starttime f formatIn