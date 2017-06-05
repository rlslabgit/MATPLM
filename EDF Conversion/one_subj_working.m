function subj_struct = one_subj_working(varargin)

%% All arguments are optional, dialog windows will open if absent
p = inputParser;
p.CaseSensitive = false;

p.addParameter('edf_loc','ask',@exist);
p.addParameter('event_loc','ask',@exist);
buttonval = @(x) assert(strcmp(x,'Standard') || strcmp(x,'Most Recent')...
    || strcmp(x,'New'));
p.addParameter('button','ask',buttonval);
p.addParameter('root','',@exist);

p.parse(varargin{:})


new_format = 'yyyy-mm-dd HH:MM:SS.fff'; % this is what the program wants

%% Get user input for filepaths and event options
% Warning, don't leave this absolute path here!
if strcmp(p.Results.edf_loc,'ask')
    [edf_file,edf_path] = uigetfile('.edf','Select input event files:',...
        p.Results.root,'MultiSelect','off');
    if edf_file == 0, error('No edf file selected'); end
    edf_loc = fullfile(edf_path,edf_file);
else
    edf_loc = p.Results.edf_loc;
end

if strcmp(p.Results.event_loc,'ask')
    [events_file,event_path] = uigetfile('.txt','Select input event files:',...
        edf_path,'MultiSelect','off');
    if events_file == 0, error('No event file selected'); end
    event_loc = fullfile(event_path,events_file);
else
    event_loc = p.Results.event_loc;
end

if strcmp(p.Results.button,'ask')
    button = questdlg(['Please specify which scoring options you would '...
        'like to use'],'Scoring Options','Standard','Most Recent','New',...
        'Most Recent');
    if isempty(button), error('Scoring option window closed'); end
else
    button = p.Results.button;
end

switch button
    case ''
        return;
    case 'Standard'
        load('standard_defaults.mat','last_used');
        sleep_defaults = last_used.sleep_defaults;
        reap_options = {last_used.apnea_defaults;...
            last_used.arousal_defaults};
        lma_defaults = {last_used.left_loc;last_used.right_loc};
        col_defaults = last_used.col_defaults;
    case 'Most Recent'
        load('last_used_defaults.mat','last_used');
        sleep_defaults = last_used.sleep_defaults;
        reap_options = {last_used.apnea_defaults;...
            last_used.arousal_defaults};
        lma_defaults = {last_used.left_loc;last_used.right_loc};
        col_defaults = last_used.col_defaults;
    case 'New'
        load('last_used_defaults.mat','last_used');
        
        %%% begin event file column prompt
        [col_defaults,cancel] = colinput(last_used.col_defaults);
        if cancel, return; end
        
        %%% begin sleep stage prompt
        prompt = {'REM','WAKE','N1','N2','N3'};
        name = 'Sleep stage event names:';
        sleep_defaults = inputdlg(prompt,name,[1, length(name)+20],...
            last_used.sleep_defaults);
        
        if isempty(sleep_defaults), return; end
        
        %%% begin apnea/arousl event prompts
        prompt = {'Apnea','Arousal'};
        name = 'Names of Arousal and Apnea Events Scored:';
        reap_options = inputdlg(prompt,name,[10, length(name)+20],...
            {last_used.apnea_defaults,last_used.arousal_defaults});
        
        if isempty(reap_options), return; end
        
        %%% begin plm event desriptors
        prompt = {'Left Leg Location','Right Leg Location'};
        name = 'EMG Channel Identifiers:';
        lma_defaults = inputdlg(prompt,name,[2, length(name)+20],...
            {last_used.left_loc,last_used.right_loc});
        
        if isempty(lma_defaults), return; end
        
        %%% save the defaults specified this time so we don't have to reenter
        last_used = struct();
        last_used(1).apnea_defaults = reap_options{1,1};
        last_used(1).arousal_defaults = reap_options{2,1};
        last_used(1).sleep_defaults = sleep_defaults';
        last_used.left_loc = lma_defaults{2,1};
        last_used.right_loc = lma_defaults{3,1};
        last_used.col_defaults = col_defaults;        
        
        save('last_used_defaults.mat','last_used');
        
        if cancel, return; end
end

apnea_defaults = cellstr(reap_options{1,1});
arousal_defaults = cellstr(reap_options{2,1});
sleep_defaults = cellstr(sleep_defaults');
left_loc = cellstr(lma_defaults{1,1});
right_loc = cellstr(lma_defaults{2,1});


%% Begin reading the event file
fid = fopen(event_loc);

tline = fgetl(fid);
indata = false;
while ~feof(fid)
    
    % Is this language dependent? Also, may be able to automatically
    % extract time format from this file
    if ~isempty(strfind(tline,'Time [hh:mm:ss.xxx]')) ||...
            ~isempty(strfind(tline,'Time [hh:mm:ss]'))
        
        if strfind(tline,'Time [hh:mm:ss.xxx]')
            tformat = 'yyyy-mm-ddTHH:MM:SS.fff';
        else
            tformat = 'yyyy-mm-ddTHH:MM:SS';
        end
        indata=true;
        label_line = {'Time','Event','Duration'};%,'Location'};
        
        sleep_stages = cell2table(cell(0,3),'VariableNames',label_line');
        arousals = cell2table(cell(0,3),'VariableNames',label_line');
        apneas = cell2table(cell(0,3),'VariableNames',label_line');
    end
    
    tline = fgetl(fid);
    
    % if the last line was the start of the data part of the file, we'll
    % begin processing things
    if indata
        dataline = strsplit(tline,'\t'); % should be tab delineated
        
        %if size(strmatch(dataline(2),event_types.Sleep_Stages),1) > 0
        if size(strmatch(dataline(col_defaults.event),sleep_defaults),1) > 0
            sleep_stages = [sleep_stages; cell2table(dataline,'VariableNames',label_line)];
        elseif size(strmatch(dataline(col_defaults.event),arousal_defaults),1) > 0
            arousals = [arousals; cell2table(dataline,'VariableNames',label_line)];
        elseif size(strmatch(dataline(col_defaults.event),apnea_defaults),1) > 0
            apneas = [apneas; cell2table(dataline,'VariableNames',label_line)];
        end
    end
    
end

fclose(fid);

% At the moment, we expect that Remlogic output will contain 30 second
% epochs for sleep staging. Also, hopefully all the events will contain a
% number or REM to indicate stage. This could be tough if the format is
% very different in international versions.
T = sleep_stages{:,col_defaults.event};
ep = zeros(size(T,1),1);
ep(~cellfun('isempty', strfind(T,sleep_defaults{3}))) = 1;
ep(~cellfun('isempty', strfind(T,sleep_defaults{4}))) = 2;
ep(~cellfun('isempty', strfind(T,sleep_defaults{5}))) = 3;
ep(~cellfun('isempty', strfind(T,sleep_defaults{1}))) = 5;
clear T;

arcell = {}; apcell = {};
colsneeded = [col_defaults.time col_defaults.event col_defaults.dur];
if ~isempty(arousals) 
    arcell = table2cell(arousals(:,colsneeded));
    arcell(:,1) = cellstr(datestr(datenum(arcell(:,1),tformat),new_format));
end

if ~isempty(apneas)
    apcell = table2cell(apneas(:,colsneeded));
    apcell(:,1) = cellstr(datestr(datenum(apcell(:,1),tformat),new_format));
end


%% Set up all the EDF Stuff
subj_struct = EDF_read_jhmi_rev_101(edf_loc);

% CHEAP FIX - JUST ADD THE WORD LEFT???
lbls = extractfield(subj_struct.Signals,'label');
for l = 1:size(left_loc,1)
    lidx = find(not(cellfun('isempty', strfind(lbls,left_loc{l}))));
    if isempty(lidx), continue; end
    subj_struct.Signals(lidx).label = [subj_struct.Signals(lidx).label ...
        ' - Left'];
end

for l = 1:size(right_loc,1)
    ridx = find(not(cellfun('isempty', strfind(lbls,right_loc{l}))));
    if isempty(ridx), continue; end
    subj_struct.Signals(ridx).label = [subj_struct.Signals(ridx).label ...
        ' - Right'];
end



%% Assemble structure fields
subj_struct.EDFStart = subj_struct.dateTime;
subj_struct.CISRE_HypnogramStart = ...
    datestr(datenum(sleep_stages{1,col_defaults.time},tformat),new_format); 
clear sleep_stages;

subj_struct.CISRE_Hypnogram = ep; clear ep;
subj_struct.EDFStart2HypnoInSec = etime(datevec(subj_struct.CISRE_HypnogramStart),...
    datevec(subj_struct.EDFStart));
subj_struct.CISRE_Arousal = arcell;
subj_struct.CISRE_Apnea = apcell;

end

function [in,cancel] = colinput(col_defaults)

Title = 'Enter Column No. of Each Variable:';

%%%% SETTING DIALOG OPTIONS
Options.Resize = 'on';
Options.Interpreter = 'tex';
Options.CancelButton = 'on';
Options.ButtonNames = {'OK','Cancel'};
%Option.Dim = 4;

Prompt = {};
Formats = {};
DefAns = struct([]);

Prompt(1,:) = {'Time','time',[]};
Formats(1,1).type = 'list';
Formats(1,1).style = 'radiobutton';
Formats(1,1).format = 'integer';
Formats(1,1).items = [1; 2; 3; 4; 5; 6];
DefAns(1).time = col_defaults.time;

Prompt(end+1,:) = {'Event' 'event',[]};
Formats(1,2).type = 'list';
Formats(1,2).style = 'radiobutton';
Formats(1,2).format = 'integer';
Formats(1,2).items = [1; 2; 3; 4; 5; 6];
DefAns.event = col_defaults.event;

Prompt(end+1,:) = {'Duration' 'dur',[]};
Formats(1,3).type = 'list';
Formats(1,3).style = 'radiobutton';
Formats(1,3).format = 'integer';
Formats(1,3).items = [1; 2; 3; 4; 5; 6];
DefAns.dur = col_defaults.dur;

Prompt(end+1,:) = {'Location' 'loc',[]};
Formats(1,4).type = 'list';
Formats(1,4).style = 'radiobutton';
Formats(1,4).format = 'integer';
Formats(1,4).items = [1; 2; 3; 4; 5; 6];
DefAns.loc = col_defaults.loc;

[in,cancel] = inputsdlg(Prompt,Title,Formats,DefAns,Options);
end