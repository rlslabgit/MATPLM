function [in] = getInput2(fs, ask)
%% [in] = getInput2(fs, ask)
% Display a dialog window that asks the user for several initial conditions
% and parameters. Store these conditions in the 'in' structure, to be
% passed around the main function.

if ~ask
    in = struct('fs',fs,'maxdur',10,'minIMI',10,'maxIMI',90,'lb1',0.5,'ub1',0.5,...
    'lb2',0.5,'ub2',0.5,'lopass',round(fs/2) - 25,'hipass',25,'thresh',true,...
    'ekg',true,'inlm',true);
else

Title = 'MATPLM Parameters';

%%%% SETTING DIALOG OPTIONS
Options.Resize = 'on';
Options.Interpreter = 'tex';
Options.CancelButton = 'on';
Options.ButtonNames = {'Continue','Cancel'}; %<- default names, included here just for illustration
Option.Dim = 4; % Horizontal dimension in fields

Prompt = {};
Formats = {};
DefAns = struct([]);

Prompt(1,:) = {'Sampling Rate (fs)', 'fs','hz'};
Formats(1,1).type = 'edit';
Formats(1,1).format = 'integer';
Formats(1,1).size = 80; % automatically assign the height
% Formats(1,1).unitsloc = 'bottomleft';
DefAns(1).fs = fs;

Prompt(end+1,:) = {'Low Pass filter', 'lopass','hz'};
Formats(1,2).type = 'edit';
Formats(1,2).format = 'integer';
%Formats(1,2).size = 80;
DefAns.lopass = round(fs/2) - 25; % i.e. 225 at 500 hz

Prompt(end+1,:) = {'High Pass filter', 'hipass','hz'};
Formats(1,3).type = 'edit';
Formats(1,3).format = 'integer';
%Formats(1,3).size = 80; % automatically assign the height
DefAns.hipass = 20;

Prompt(end+1,:) = {'Maximum Duration', 'maxdur','s'};
Formats(2,1).type = 'edit';
Formats(2,1).format = 'integer';
Formats(2,1).size = 80; % automatically assign the height
DefAns.maxdur = 10;

Prompt(end+1,:) = {'Maximum IMI', 'maxIMI','s'};
Formats(2,2).type = 'edit';
Formats(2,2).format = 'integer';
%Formats(2,2).size = 80; % automatically assign the height
DefAns.maxIMI = 90;

Prompt(end+1,:) = {'Minimum IMI', 'minIMI','s'};
Formats(2,3).type = 'edit';
Formats(2,3).format = 'integer';
%Formats(2,3).size = 80; % automatically assign the height
DefAns.minIMI = 10;

% Prompt(end+1,:) = {'Morphology Requirement' 'morph',[]};
% Formats(3,1).type = 'check';
% DefAns.morph = true;

Prompt(end+1,:) = {'Intervening LM Breakpoint' 'inlm',[]};
Formats(3,1).type = 'check';
DefAns.inlm = true;

Prompt(end+1,:) = {'EKG Removal' 'ekg',[]};
Formats(3,2).type = 'check';
DefAns.ekg = true;

Prompt(end+1,:) = {'Dynamic Threshold','thresh',[]};
Formats(3,3).type = 'check';
DefAns.thresh = true;

[in,~] = inputsdlg(Prompt,Title,Formats,DefAns,Options);
end

end
