function get_event_data(filepath)
%% Read event names from table

%% Group events from subject file
fid = fopen(filepath);

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
        label_line = {'Time','Event','Duration','Location'};
        
        sleep_stages = cell2table(cell(0,4),'VariableNames',label_line');
        arousals = cell2table(cell(0,4),'VariableNames',label_line');
        apneas = cell2table(cell(0,4),'VariableNames',label_line');
        lms = cell2table(cell(0,4),'VariableNames',label_line');
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
        elseif size(strmatch(dataline(col_defaults.event),lm_ids),1) > 0
            lms = [lms; cell2table(dataline,'VariableNames',label_line)];
        end
    end
    
end

fclose(fid);

if ~params.ars, arousals = table(); end
if ~params.aps, apneas = table(); end

% At the moment, we expect that Remlogic output will contain 30 second
% epochs for sleep staging. Also, hopefully all the events will contain a
% number or REM to indicate stage. This could be tough if the format is
% very different in international versions.
T = sleep_stages{:,col_defaults.event};
ep = zeros(size(T,1),1);
ep(~cellfun('isempty', strfind(T,sleep_defaults{3}))) = 1;
ep(~cellfun('isempty', strfind(T,sleep_defaults{4}))) = 2;
ep(~cellfun('isempty', strfind(T,sleep_defaults{5}))) = 3;
ep(~cellfun('isempty', strfind(T,'4'))) = 4;
ep(~cellfun('isempty', strfind(T,sleep_defaults{1}))) = 5;


end