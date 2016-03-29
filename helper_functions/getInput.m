function [in] = getInput(ask)
%% [in] = getInput()
% Display a dialog window that asks the user for several initial conditions
% and parameters. Store these conditions in the 'in' structure, to be
% passed around the main function.
%
% TODO: add an optional parameter that does not display the dialog window
% and defaults to the structure below

% default parameters
in = struct('fs',500,'maxdur',10,'minIMI',10,'maxIMI',90,'lb1',0.5,'ub1',0.5,...
    'lb2',0.5,'ub2',0.5,'lopass',225,'hipass',25,'dynthresh',1,'morph',1,...
    'minNumIMI',3);

if ask == 1
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
    
    for i = 1:size(valnames,1)-1 % some extra-struct values I want
        in.(valnames{i}) = str2double(answer{i});
    end
end

end