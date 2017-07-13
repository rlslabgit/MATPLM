function [in,cancel] = getInput2(fs, ask)
%% [in] = getInput2(fs, ask)
% Display a dialog window that asks the user for several initial conditions
% and parameters. Store these conditions in the 'in' structure, to be
% passed around the main function. Program will terminate if cancel is
% true. Based off of the file 'inputsdlg.m', which is a script by Takeshi 
% Ikuma that expands the functionality of matlab's built-in input dialogs.
%
% See the bottom of this function for several parameters related to the
% classification of PLM that most users will have no desire to change, but
% can do so here.
%
% inputs:
%   - fs - sampling rate (for filter estimates)
%   - ask - if false, just returns the default struct

if ~ask
    in = struct('fs',fs,'maxdur',10,'bmaxdur',15,'minIMI',10,'maxIMI',90,...
        'lb1',0.5,'ub1',0.5,'lb2',0.5,'ub2',0.5,'lopass',...
        round(fs * 0.45),'hipass',20,'thresh',true,'ekg',true,'inlm',...
        true,'minNumIMI',3,'maxcomb',4);

    cancel = false;
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
Formats(1,2).format = 'float';
%Formats(1,2).size = 80;
DefAns.lopass = round(fs*0.45); % i.e. 225 at 500 hz

Prompt(end+1,:) = {'High Pass filter', 'hipass','hz'};
Formats(1,3).type = 'edit';
Formats(1,3).format = 'float';
%Formats(1,3).size = 80; % automatically assign the height
DefAns.hipass = 20;

Prompt(end+1,:) = {'Maximum Duration (monolateral)', 'maxdur','s'};
Formats(2,1).type = 'edit';
Formats(2,1).format = 'float';
Formats(2,1).size = 80; % automatically assign the height
DefAns.maxdur = 10;

Prompt(end+1,:) = {'Maximum IMI', 'maxIMI','s'};
Formats(2,2).type = 'edit';
Formats(2,2).format = 'float';
%Formats(2,2).size = 80; % automatically assign the height
DefAns.maxIMI = 90;

Prompt(end+1,:) = {'Minimum IMI', 'minIMI','s'};
Formats(2,3).type = 'edit';
Formats(2,3).format = 'float';
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

[in,cancel] = inputsdlg(Prompt,Title,Formats,DefAns,Options);

% Currently, there is no option to change these features in the dialog box
% most users will not care.

% respiratory event associations
in.lb1 = 2;
in.ub1 = 10.25;

% arousal event associations
in.lb2 = 0.5;
in.ub2 = 0.5;

% intermovement intervals for a PLM run
in.minNumIMI = 3;

% max monolateral movements to combine into a bilateral
in.maxcomb = 4;

% maximum duration of a bilateral movement
in.bmaxdur = 15;
end

end
