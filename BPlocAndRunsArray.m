%% Create BPloc
%  col 1: Break point location
%  col 2: Number of leg movements
%  col 3: PLM =1, no PLM = 0
%  col 4: #LM if PLM

function BPloc = BPlocAndRunsArray(CLM,minNumIMI)

BPloc(:,1)=find(CLM(:,9)); %% BP locations

% Add number of movements until next breakpoint to column 2
BPloc(1:end-1,2) = BPloc(2:end,1) - BPloc(1:end-1,1);
BPloc(end,2) = size(CLM,1) - BPloc(end,1) + 1;

% Mark whether a run of LM meets the minimum requirement for number of IMI
BPloc(:,3) = 0;
BPloc(BPloc(:,2) > minNumIMI,3) = 1;

% Mark the number of movements in each PLM series
BPloc(:,4) = 0;
BPloc(BPloc(:,3) == 1,4) = BPloc(BPloc(:,3) == 1,2);

end