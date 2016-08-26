function [lm_tbl,PLM] = plm_from_txt(filename,varargin)
%% [PLMS,PLM] = plm_from_txt(filename,varargin)
% This function reads in a text file containing manually (or otherwise
% externally) scored leg movements.
%
% inputs:
%   - filename - path to PLM event file
%   - hypnostart - (optional) start time of hypnogram in form 'YYYY-MM-DD HH:MM:SS'
%                - defaults to August 23, 2016 9:00 pm
%
% TODO: support different event types - right now we don't care as long as
% it is in the LM txt file

% testing path
% 'D:\Glutamate Study\AidRLS, G00583_V1N1 - 5_15_2013\G00583_V1N1 AidRLS-Events PLM.txt'

p = inputParser;
p.CaseSensitive = false;

p.addRequired('filename',@exist)
p.addOptional('epochstage','default',@exist)

% actually this should probably be required. Wait just kidding, what do I
% need this for? I can use an arbitrary start date
p.addOptional('hypnostart','2016-8-23 21:00:00',@(x) datenum(x));

% Matlab is pretty good at detecting headerlines, so you should only change
% this value if something is going wrong
p.addParameter('headerlines',-1,@(x) x >= 0);

% locations of the start time (t) in some parseable date format, type of
% the event and duration in seconds
p.addParameter('t_type_dur',[1,2,3],@(x) size(x,1) == 3);

% date format of the 'start' column of the input file. No check on this, so
% be careful I guess
p.addParameter('datef','yyyy-mm-ddTHH:MM:SS.fff')

p.parse(filename,varargin{:})

if strcmp(p.Results.epochstage,'default'), ep = zeros(960,1);
else
    T = readtable(p.Results.epochstage);
  
    ep = zeros(size(T,1),1);
    ep(~cellfun('isempty', strfind(T,'1'))) = 1;
    ep(~cellfun('isempty', strfind(T,'2'))) = 2;
    ep(~cellfun('isempty', strfind(T,'3'))) = 3;
    ep(~cellfun('isempty', strfind(T,'4'))) = 4;
    ep(~cellfun('isempty', strfind(T,'REM'))) = 5;
    clear T
end



if p.Results.headerlines < 0, lm_tbl = readtable(p.Results.filename);
else lm_tbl = readtable(p.Results.filename,'headerlines',p.Results.headerlines); end

LM = zeros(size(lm_tbl,1),2);

% arbitrary start time 60 seconds prior to the first movement. We'll go
% back and replace actual times later
tmp_start = datenum(lm_tbl{1,1},p.Results.datef) - 60/86400;


% just arbitrarily make it 500 hz... it doesn't matter, but it's easier to
% manipulate the date input than to rewrite my scoring code
LM(:,1) = datenum(lm_tbl{:,1},p.Results.datef);
LM(:,1) = round((LM(:,1) - tmp_start) * 86400 * 500);
lm_tbl.pointid = LM(:,1);

params = getInput2(500,1);

LM(:,2) = LM(:,1) + 500 * lm_tbl{:,3};
CLM = candidate_lms(LM,[],ep,params);
x = periodic_lms(CLM,params);

% put this all into a table for easier access
P = array2table(x(:,[1:4,6,8:9]));


x = innerjoin(P,lm_tbl,'leftkeys',1,'rightkeys','pointid',...
    'rightvariables',[p.Results.t_type_dur(1),p.Results.t_type_dur(3)]);

starts = datetime(datevec(x{:,8},p.Results.datef));
stops = starts(:,1) + seconds(x{:,9});

PLM = table(starts,stops,x{:,3},x{:,4},x{:,5},x{:,6},x{:,7});
PLM.Properties.VariableNames = {'start','stop','duration','imi',...
    'sleepstage','epoch','breakpoint'};

end