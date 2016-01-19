function [CLM] = lazyMP(rdsEMG,ldsEMG,rLM,lLM,epochStage,doMed)

% Remove that don't pass median
if doMed == 1
    rLM = cutLowMedian(rdsEMG,rLM,2,500);
    lLM = cutLowMedian(ldsEMG,lLM,2,500);
end

% Combine left and right and sort.
rLM(:,13) = 1; lLM(:,13) = 2;
combLM = [rLM;lLM];
combLM = sortrows(combLM,1);
CLM = removeOverlap(combLM,500);

% Add duration
CLM(:,3) = (CLM(:,2)-CLM(:,1))/500;
% Add IMI col 4
CLM = getIMI(CLM,500);
% Add sleep stage
CLM(:,6) = epochStage(round(CLM(:,1)/30/500+.5));

% Don't care about cols 7,8,10

% Add breakpoints. Technically, the breakpoint for too long movements
% should go on the next movement, I think, but I'm going to let this slide
% for now...
CLM(:,9) = CLM(:,4) > 90 | CLM(:,3) > 10;
aftLong = find(CLM(:,3) > 10) + 1;
aftLong = aftLong(aftLong < size(CLM,1));
CLM(aftLong,9) = 1;
BPloc = BPlocAndRunsArray(CLM,3);

% Mark the periodic movements
CLM = markPLM3(CLM,BPloc,500);
end