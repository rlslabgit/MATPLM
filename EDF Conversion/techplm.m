%function PLM = techplm()
% can be used for batch processing with a little work

f = 'D:\Glutamate Study\AidRLS, G82828_V1N2 - 8_17_2015\G82828_V1N2 AidRLS-Events PLM.txt';

T = readtable(f,'headerlines',10);
formatIn = 'yyyy-mm-ddTHH:MM:SS'; % original didn't have milliseconds

% WARNING: this is not the start time used for PSG analysis. Make sure we
% give these in the correct way.
starttime = T.Var1(1);

T(1,:) = [];

tPLM = zeros(size(T,1),2);
starttime = repmat(starttime,[size(T,1) 1]);
tPLM(:,1) = etime(datevec(T.Var1(:),formatIn),datevec(starttime(:),formatIn));
tPLM(:,1) = tPLM(:,1) * 500;
tPLM(:,2) = tPLM(:,1) + T.Var3(:)*500;

clear T starttime f formatIn