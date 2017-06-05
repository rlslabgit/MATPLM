function [CLM,CLMnr] = candidate_lms(rLM,lLM,epochStage,params,tformat,varargin)
%% CLM = candidate_lms(rLM,lLM,epochStage,params, varargin)
% Determine candidate leg movements for PLM from monolateral LM arrays. If
% either rLM or lLM is empty ([]), this will return monolateral candidates,
% otherwise if both are provided they will be combined according to current
% WASM standards. Adds other information to the CLM table, notably
% breakpoints to indicate potential ends of PLM runs, sleep stage, etc. Of
% special note, the 13th column of the output array indicates which leg the
% movement is from: 1 is right, 2 is left and 3 is bilateral.
%
% edit 11Jul16 - correct duration exclusion logic, recode breakpoint events
%
% inputs:
%   - rLM - array from right leg (needs start and stop times)
%   - lLM - array from left leg
%   - epochStage - hypnogram, expects 30 second epochs
%   - params - output struct from 'getInput2.m'
%   - tformat - format of datetime in arousal and apnea events
%
% optional inputs (in this order):
%   - apd - apnea data, from the original subject struct
%   - ard - arousal data
%   - hgs - hypnogram start time
%
% IMPORTANT! This file only for use with EDF+ scoring procedure, which
% fails when we treat the duration as a string.


if nargin >= 6, apd = varargin{1}; end
if nargin >= 7, ard = varargin{2}; end
if nargin == 8, hgs = varargin{3}; end

CLMnr = [];

if ~isempty(rLM) && ~isempty(lLM)
    % Reduce left and right LM arrays to exclude too long movements, but add
    % breakpoints to the following movement
    rLM(:,3) = (rLM(:,2) - rLM(:,1))/params.fs;
    lLM(:,3) = (lLM(:,2) - lLM(:,1))/params.fs;
    
    rLM = rLM(rLM(:,3) >= 0.5,:);
    lLM = lLM(lLM(:,3) >= 0.5,:);
    
    rLM(rLM(1:end-1,3) > params.maxdur, 9) = 4; % too long mclm
    lLM(lLM(1:end-1,3) > params.maxdur, 9) = 4; % too long mclm
    
    % Combine left and right and sort.
    CLM = rOV2(lLM,rLM,params.fs);
elseif ~isempty(lLM)
    lLM(:,3) = (lLM(:,2) - lLM(:,1))/params.fs;
    lLM = lLM(lLM(:,3) >= 0.5,:);
    lLM(lLM(1:end-1,3) > params.maxdur, 9) = 4; % too long mclm
    
    CLM = lLM;
    CLM(:,11:13) = 0; % we need these columns anyway
elseif ~isempty(rLM)
    rLM(:,3) = (rLM(:,2) - rLM(:,1))/params.fs;
    rLM = rLM(rLM(:,3) >= 0.5,:);
    rLM(rLM(1:end-1,3) > params.maxdur, 9) = 4; % too long mclm
    
    CLM = rLM;
    CLM(:,11:13) = 0; % we need these columns anyway
else
    CLM = [];
end

if sum(CLM) == 0, return; end
% if a bilateral movement consists of one or more monolateral movements
% that are longer than 10 seconds (standard), the entire combined movement
% is rejected, and a breakpoint is placed on the next movement. When
% inspecting IMI of CLM later, movements with the bp code 4 will be
% excluded because IMI is disrupted by a too-long LM
contain_too_long = find(CLM(:,9) == 4);
CLM(contain_too_long+1,9) = 4;
CLM(contain_too_long,:) = [];

% add breakpoints if the duration of the combined movement is greater
% than 15 seconds (standard) or if a bilateral movement is made up of
% greater than 4 (standard) monolateral movements. These breakpoints
% are actually added to the subsequent movement, and the un-CLM is
% removed.
CLM(:,3) = (CLM(:,2) - CLM(:,1))/params.fs;
CLM(find(CLM(1:end-1,3) > params.bmaxdur) + 1,9) = 3; % too long bclm
CLM(find(CLM(1:end-1,4) > params.maxcomb) + 1,9) = 5; % too many cmbd mvmts

CLM(CLM(1:end,4) > params.maxcomb |...
    CLM(1:end,3) > params.bmaxdur,:) = [];

CLM(:,4) = 0; % clear out the #combined mCLM


% The area of the leg movement should go here. However, it is not
% currently well defined in the literature for combined legs, and we
% have omitted it temporarily
CLM(:,10:12) = 0;
if exist('ard','var') && exist('hgs','var')
    CLM = event_assoc('Arousal',CLM,ard,hgs,params.ub2,params.lb2,...
        params.fs,tformat);
end
% Add apnea events (col 11) and arousal events (col 12)
if exist('apd','var') && exist('hgs','var')
    CLM = event_assoc('Apnea',CLM,apd,hgs,params.ub1,params.lb1,...
        params.fs,tformat);
end

CLMnr = CLM(CLM(:,11) == 0,:);


% If there are no CLM, return an empty vector
if ~isempty(CLM)
    % Add IMI (col 4), sleep stage (col
    % 6). Col 5 is reserved for PLM marks later
    CLM = getIMI(CLM, params.fs);
    CLMnr = getIMI(CLMnr, params.fs);
    
    % add breakpoints if IMI > 90 seconds (standard)
    
    % add breakpoints if IMI < minIMI. This is according to new standards.
    % I believe we also need a breakpoint after this movement, so that a
    % short IMI cannot begin a run of PLM
    if params.inlm
        CLM(CLM(:,4) < params.minIMI, 9) = 2; % short IMI
        CLMnr(CLMnr(:,4) < params.minIMI, 9) = 2; % short IMI
        
        % if the following line is uncommented, CLM with short IMI will not
        % be able to start a PLM run
        % CLM(find(CLM(:,4) < params.minIMI) + 1, 9) = 1;
    else
        CLM = removeShortIMI(CLM,params);
        CLMnr = removeShortIMI(CLMnr,params);
    end
    
    if ~isempty(epochStage)
        CLM(:,6) = epochStage(round(CLM(:,1)/30/params.fs+.5));
        CLMnr(:,6) = epochStage(round(CLMnr(:,1)/30/params.fs+.5));
    end
    
    % Add movement start time in minutes (col 7) and sleep epoch number
    % (col 8)
    CLM (:,7) = CLM(:,1)/(params.fs * 60);
    CLMnr (:,7) = CLMnr(:,1)/(params.fs * 60);
    CLM (:,8) = round (CLM (:,7) * 2 + 0.5);
    CLMnr (:,8) = round (CLMnr (:,7) * 2 + 0.5);
        
    CLM(CLM(:,4) > params.maxIMI,9) = 1;
    CLMnr(CLMnr(:,4) > params.maxIMI,9) = 1;
end

end

function PLM = event_assoc(event_type,PLM,EventData,HypnogramStart,ub,lb,fs,tformat)
%% newPLM = event_assoc(event_type,PLM,EventData,HypnogramStart,lb,ub,fs)
% PLMApnea adds Apnea Events to the 11th col of the PLM Matrix if there is
% a PLM within -lb,+ub seconds of the event endpoint
% EventData is the CISRE_Apnea matrix
% HypnogramStart is the first data point

if strcmp(event_type,'Arousal')
    assoc_col = 12;
elseif strcmp(event_type,'Apnea')
    assoc_col = 11;
end


if size(EventData, 1) == 0, return; end
%if EventData{1,1} == 0, return; end     Do we need to check this anymore?

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% start
event_ends = zeros(size(EventData,1),1);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% start
start_vec = datevec(HypnogramStart);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% end

for ii = 1:size(EventData,1)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% start
    event_start = datevec(EventData{ii,1},tformat);
    event_ends(ii) = round(etime(event_start,start_vec) + ...
        str2double(EventData{ii,3})) * fs + 1;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% end    
end

event_intervals = [event_ends - fs*lb, event_ends + fs*ub];

% THIS IS SO INEFFICIENT
% tic; newPLM = PLM;
% for ii = 1:size(EventData, 1)
%     for jj = 1:size(newPLM, 1)
%         if ~isempty(intersect(newPLM(jj,1):newPLM(jj,2),...
%                 event_intervals(ii,1):event_intervals(ii,2)))
%             newPLM(jj,assoc_col) = 1;
%         end
%     end
% end
% fprintf(1,'Loop version took %.3f seconds\n',toc);
% Better? Yes, by a factor of 1000
% tic;

ev_vec = zeros(max(event_intervals(end,2),PLM(end,2)),1);
for j = 1:size(event_intervals,1)
    ev_vec(event_intervals(j,1):event_intervals(j,2)) = 1;
end
for j = 1:size(PLM,1)
    if any(ev_vec(PLM(j,1):PLM(j,2)) == 1), PLM(j,assoc_col) = 1; end
end
end
    

function [CLM] = rOV2(lLM,rLM,fs)
% Combine bilateral movements if they are separated by < 0.5 seconds

% combine and sort LM arrays
rLM(:,13) = 1; lLM(:,13) = 2;
combLM = [rLM;lLM];
combLM = sortrows(combLM,1); % sort by start time

% distance to next movement
CLM = combLM;
CLM(:,4) = 1;

i = 1;

while i < size(CLM,1)
    % make sure to check if this is correct logic for the half second
    % overlap period...
    if isempty(intersect(CLM(i,1):CLM(i,2),(CLM(i+1,1)-fs/2):CLM(i+1,2)))
        i = i+1;
    else
        CLM(i,2) = max(CLM(i,2),CLM(i+1,2));
        CLM(i,4) = CLM(i,4) + CLM(i+1,4);
        CLM(i,9) = max([CLM(i,9) CLM(i+1,9)]);
        if CLM(i,13) ~= CLM(i+1,13)
            CLM(i,13) = 3;
        end
        CLM(i+1,:) = [];
    end
end

end

function LM = getIMI(LM,fs)
%% LM = getIMI(LM,fs)
% getIMI calculates intermovement interval and stores in the fourth column
% of the input array. IMI is onset-to-onset and measured in seconds

LM(1,4) = 9999; % archaic... don't know if we need this
LM(2:end,4) = (LM(2:end,1) - LM(1:end-1,1))/fs;

end

function CLMt = removeShortIMI(CLM,params)
% Old way of scoring - remove movements with too short IMI, then
% recalculate IMI and see if it fits now. There's probably a way to
% vectorize this for speed, but I honestly don't care, no one should use
% this anymore.
rc = 1;      
CLMt = [];

for rl = 1:size(CLM,1);
    if CLM (rl,4) >= params.minIMI;
       CLMt(rc,:) = CLM(rl,:);
       rc = rc + 1;
    elseif rl < size(CLM,1)
        CLM(rl+1,4)= CLM(rl+1,4)+CLM(rl,4);
    end
  
end

CLMt = getIMI(CLMt,params.fs);
end