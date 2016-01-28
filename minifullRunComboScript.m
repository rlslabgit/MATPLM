%% Runs all initiation and MasterPlan steps in order to locate and describe
% all PLM throughout the night, on both legs.
% Parameter: the workplace structure containing EMG channels and relevant
% recording information, as converted by Allen_Ebm_2_Matlab.m
%

function [CLMt,CLM,rCLM,lCLM,CLMlabs,PLM,PLMt,epochStage,ldsEMG,rdsEMG,...
    HypnogramStart] = minifullRunComboScript(StructName)

% Note about outputs: matrices for any sleep stage, as well as for
% calculating IMI can be computed from the appropriate PLM or PLMt matrix.
% PLMt CANNOT be extracted from PLM in a similar way, because it requires
% masterPlanForPLMt method. 
%
% i.e. PLMS = PLM(PLM(:,6) > 0,:); [all PLM with sleep stage > 0]
%      PLMIMI = PLM(PLM(:,4) < 90,:); [all PLM with IMI < 90 seconds]


% Get user input from input-dlg window
[in,doDynamic,doMed] = getInput();

% Extract Info from structure 
% Get filepath for left and right EMG data
for i = 1:size(StructName.Signals,2)
    if strcmp(strtrim(StructName.Signals(i).label),'Left Leg')
        lidx = i;
    elseif strcmp(strtrim(StructName.Signals(i).label),'Right Leg')
        ridx = i;
    end
end
[lEMG] = StructName.Signals(lidx).data;
[rEMG] = StructName.Signals(ridx).data;


% Get sleep start and end
try
    sleepRecordStart = StructName.EDFStart2HypnoInSec * in.fs + 1;
catch
    warning('Reference to non-existent field ''EDFStart2HypnoInSec''');
    warning('Setting sleepRecordStart to 1');
    sleepRecordStart = 1;
end

% Get sleep end and hypnogram
try
    sleepRecordEnd = sleepRecordStart + ...
        size(StructName.CISRE_Hypnogram, 1) * 30 * in.fs;
    [epochStage] = StructName.CISRE_Hypnogram;
catch
    warning('Reference to non-existent field ''CISRE_Hypnogram''');
    warning('Assuming (possibly incorrectly) that TST < 8 hours');
    warning('Sleep staging information will be unavailable');
    
    sleepRecordEnd = sleepRecordStart + 960 * 30 * in.fs;
    [epochStage] = zeros(960,1);
end

% Make sure the sleep record end (from size of hypnogram) is not beyond the
% end of the EMG recording. The two channels should always be the same
% length, but check to make sure.
if sleepRecordEnd >= max(size(rEMG,1),size(lEMG,1))
    sleepRecordEnd = min(size(rEMG,1),size(lEMG,1)); 
end;

% If there are any NaNs in the record, filtering will fail. We must end the
% record when a NaN is found
if size(find(isnan(lEMG(sleepRecordStart:sleepRecordEnd)),1)) > 0, sleepRecordEnd = find(isnan(lEMG(sleepRecordStart:sleepRecordEnd)),1) - 1; end; 
if size(find(isnan(rEMG(sleepRecordStart:sleepRecordEnd)),1)) > 0, sleepRecordEnd = find(isnan(rEMG(sleepRecordStart:sleepRecordEnd)),1) - 1; end; 

% Generate filtered EMG data
[ldsEMG] = filterAnddsEMG(in.hipass,in.lopass,in.fs,lEMG,sleepRecordStart,sleepRecordEnd);
[rdsEMG] = filterAnddsEMG(in.hipass,in.lopass,in.fs,rEMG,sleepRecordStart,sleepRecordEnd);

% Get apnea, arousal data
try
    ApneaData = StructName.CISRE_Apnea;   
catch
    warning('Reference to non-existent filed ''CISRE_Apnea''');
    ApneaData = {0,0,0};
end

try
    ArousalData = StructName.CISRE_Arousal;   
catch
    warning('Reference to non-existent filed ''CISRE_Arousal''');
    ArousalData = {0,0,0};
end

try
    HypnogramStart = StructName.CISRE_HypnogramStart;
catch
    warning('Reference to non-existent field ''CISRE_HypnogramStart''');
    HypnogramStart = '2000-01-01 00:00:00';
end

if doDynamic == 1
    [nldsEMG,~,lminT] = dynamicThresholdX(ldsEMG,500);
    [nrdsEMG,~,rminT] = dynamicThresholdX(rdsEMG,500);
%     nldsEMG = dynamicThreshold2(ldsEMG,in.fs); % Use normalized, DON'T RETURN
%     nrdsEMG = dynamicThreshold2(rdsEMG,in.fs);
     
    % Run ComboMasterPlan w/ thresholds at 4 and 10 
%     [CLM,PLM,rCLM,lCLM,PLMnoAp,CLMnoAp] = miniCOMBOmasterPlanForPLM(nrdsEMG,nldsEMG,...
%         4,4,10,10,0.5,0.5,in.fs,in.maxdur,epochStage,30,in.maxIMI,3,...
%         ApneaData,ArousalData,HypnogramStart,in.lb1,in.ub1,in.lb2,in.ub2,doMed);

    % Run ComboMasterPlan w/ thresholds minT
    [CLM,PLM,rCLM,lCLM,PLMnoAp,CLMnoAp] = miniCOMBOmasterPlanForPLM(nrdsEMG,nldsEMG,...
        lminT,rminT,lminT+6,rminT+6,0.5,0.5,in.fs,in.maxdur,epochStage,30,in.maxIMI,3,...
        ApneaData,ArousalData,HypnogramStart,in.lb1,in.ub1,in.lb2,in.ub2,doMed);
    
else
    % Calculates low threshold from dsEMG data
    llowThreshold = scanning2(ldsEMG,in.fs);
    rlowThreshold = scanning2(rdsEMG,in.fs);
    
    % Run ComboMasterPlan w/ auto thresholds
    [CLM,PLM,rCLM,lCLM,PLMnoAp,CLMnoAp] = miniCOMBOmasterPlanForPLM(rdsEMG,ldsEMG,...
        rlowThreshold,llowThreshold,rlowThreshold+6,llowThreshold+6,0.5,0.5,...
        in.fs,in.maxdur,epochStage,30,in.maxIMI,3,ApneaData,ArousalData,...
        HypnogramStart,in.lb1,in.ub1,in.lb2,in.ub2,doMed);
end

% Calculate PLMt: PLM with minimum IMI requirement (WASM standard is 5)
[PLMt,CLMt] = minimasterPlanForPLMt(CLM,in.minIMI,in.fs,in.maxIMI,3,in.maxdur);
[PLMtnoAp] = minimasterPlanForPLMt(CLMnoAp,in.minIMI,in.fs,in.maxIMI,3,in.maxdur);

% Write the results to a file in the Patient Data Files subfolder
% writeToFile(in,PLM,PLMnoAp,PLMt,PLMtnoAp,epochStage,doDynamic,doMed,inputname(1),...
%     CLM,CLMt);

% Plot results, LM1 is left leg, LM2 is right leg, PLM is all PLMS in sleep
% with IMI > minIMIDuration
PLMSt = PLMt(PLMt(:,6) > 0,:);
PlotStuff(ldsEMG,rdsEMG,'LM1',lCLM,'LM2',rCLM,'PLM',PLMSt,'HypnoStart',...
    HypnogramStart);



% Arrange extra outputs
PLMS = PLM(PLM(:,6) > 0,:); PLMSIMI = PLMS(PLMS(:,4) < 90,:);

Table_Headers = {'Start','End','Duration','IMI','isPLM','SleepStage',...
    'Start_in_Min','StartEpoch','Breakpoint','Area','isApnea','isArousal',...
    'Lateraltiynessment'};

CLMlabs = array2table(CLM,'VariableNames',Table_Headers);
end



% Display a dialog window that asks the user for several initial conditions
% and parameters.
function [in,doDynamic,doMed] = getInput()
in = struct('fs',500,'maxdur',10,'minIMI',5,'maxIMI',90,'lb1',0.5,'ub1',0.5,...
    'lb2',0.5,'ub2',0.5,'lopass',225,'hipass',25);

prompt = {'Sampling Rate:',...
    'Max Movement Duration:'...
    'Min IMI Duration:',...
    'Max IMI Duration:',...
    'Apnea lower-bound',...
    'Apnea upper-bound',...
    'Arousal lower-bound',...
    'Arousal upper-bound',...
    'Low-pass (hz):',...
    'High-pass (hz):',...
    'Dynamic threshold (0/1)',...
    'Remove low median (0/1)'};

dlg_title = 'Definitions';
numLines = 1;

def = {'500',... % fs
    '10',...     % max dur
    '10',...      % min IMI
    '90',...     % max IMI
    '0.5',...    % lb ap
    '0.5',...    % ub ap    
    '0.5',...    % lb ar
    '0.5',...    % ub ar
    '225',...    % low pass
    '25'...      % high pass
    '1',...
    '1'};       
    
answer = inputdlg(prompt,dlg_title,numLines,def);
valnames = fieldnames(in);

for i = 1:size(valnames,1) % some extra-struct values I want 
   in.(valnames{i}) = str2num(answer{i});  %#ok<*ST2NM>
end

doDynamic = str2num(answer{size(valnames,1)+1});
doMed = str2num(answer{size(valnames,1)+2});
end