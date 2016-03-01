function [plm_outputs] = matplm_main(psg_struct)

params = getInput; % store the parameters in a structure

% find the LAT and RAT channels in the structure
% TODO: support different channel naming styles
lbls = extractfield(psg_struct.Signals,'label');
lidx = find(not(cellfun('isempty', strfind(lbls,'Left'))));
ridx = find(not(cellfun('isempty', strfind(lbls,'Right'))));
lEMG = psg_struct.Signals(lidx).data;
rEMG = psg_struct.Signals(ridx).data;

% find start and end of the record and hypnogram vector
% TODO: reasonable error handling (other file is too wordy)
epochStage = StructName.CISRE_Hypnogram;
sleepRecordStart = StructName.EDFStart2HypnoInSec * params.fs + 1;
sleepRecordEnd = sleepRecordStart + size(epochStage, 1) * 30 * params.fs;

% cannot be past edge of EMG
if sleepRecordEnd >= max(size(rEMG,1),size(lEMG,1))
    sleepRecordEnd = min(size(rEMG,1),size(lEMG,1)); 
end

% If there are any NaNs in the record, filtering will fail. We must end the
% record when a NaN is found
if size(find(isnan(lEMG(sleepRecordStart:sleepRecordEnd)),1)) > 0 
    sleepRecordEnd = find(isnan(lEMG(sleepRecordStart:sleepRecordEnd)),1) - 1; 
end 
if size(find(isnan(rEMG(sleepRecordStart:sleepRecordEnd)),1)) > 0 
    sleepRecordEnd = find(isnan(rEMG(sleepRecordStart:sleepRecordEnd)),1) - 1; 
end 

end

% Display a dialog window that asks the user for several initial conditions
% and parameters.
function [in] = getInput()
in = struct('fs',500,'maxdur',10,'minIMI',10,'maxIMI',90,'lb1',0.5,'ub1',0.5,...
    'lb2',0.5,'ub2',0.5,'lopass',225,'hipass',25,'dynthresh',1,'morph',1);

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
    'Morphology Criterion (0/1)'};

dlg_title = 'Parameters';
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
    '1',...      % dynamic threshold
    '1'};        % morphology criterion   
    
answer = inputdlg(prompt,dlg_title,numLines,def);
valnames = fieldnames(in);

for i = 1:size(valnames,1) % some extra-struct values I want 
   in.(valnames{i}) = str2double(answer{i});
end

end

% perform simple error checking on epoch stage and sleep record start/end
function [es,ss,se] = errcheck(es0,ss0,se0,LAT,RAT)


end