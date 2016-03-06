function [plm_outputs] = matplm_main(psg_struct,varargin)
%% [plm_outputs] = matplm_main(psg_struct)
% The main driving function for the MATPLM program. Input is the full
% subject structure, transferred from EDF format with EDF
% Conversion/Generic_Convert.m
%
% TODO: add support for one leg? Was thinking I would just make a separate
% file for that
sep_flag = 0;

addpath('helper_functions')

% TODO: Eventually, we'll run this file differently for seperate legs
if strcmp('separate_legs',varargin)
    display('MATPLM will calculate CLM/PLM for each leg seperately');
    sep_flag = 1;
end

% Unless the user specifies 'default_params', ask for them.
if strcmp('default_params',varargin)
    params = getInput(0);
else
    params = getInput(1);
end

% find the LAT and RAT channels in the structure
% TODO: support different channel naming styles
lbls = extractfield(psg_struct.Signals,'label');
lidx = find(not(cellfun('isempty', strfind(lbls,'Left'))));
ridx = find(not(cellfun('isempty', strfind(lbls,'Right'))));

lEMG = psg_struct.Signals(lidx(1)).data;
rEMG = psg_struct.Signals(ridx(1)).data;

% find hypnogram/apnea/arousal vectors, start and stop times (in data
% points) of the actual sleep scoring and the clock time start. The
% hypnogram is expected to use standard 30 sec epochs.
[epochStage,rec_start,rec_end,apnea_data,arousal_data,start_time] = ...
    errcheck_ss(psg_struct,lEMG,rEMG,params.fs);

% Truncate, filter and rectify EMG signals.
lEMG = butter_rect(params,lEMG,rec_start,rec_end);
rEMG = butter_rect(params,rEMG,rec_start,rec_end);

% Apply dynamic threshold, if desired. Temporarily store the EMG in n*EMG
% so that the dynamically adjusted data is not plotted.
if params.dynthresh == 1
    [nlEMG,~,lminT] = dynamicThresholdX(lEMG,params.fs);
    [nrEMG,~,rminT] = dynamicThresholdX(rEMG,params.fs);
else
    % Store copy of EMG 
    nlEMG = lEMG;
    nrEMG = rEMG;
    % Naively estimate low threshold
    lminT = scanning2(lEMG,params.fs);
    rminT = scanning2(rEMG,params.fs);
end

% Find all leg movements on the left and right legs.
min_below = 0.5; % time below low threshold to end movement
min_above = 0.5; % time above low threshold to start movement
% Also note the '+6' after *minT: the high threshold is traditionally 8
% microvolts above the noise (or 6 above the low threshold)
lLM = findIndices(nlEMG,lminT,lminT+6,min_below,min_above,params.fs);
rLM = findIndices(nrEMG,rminT,rminT+6,min_below,min_above,params.fs);

% optionally apply morphology criterion
if params.morph == 1
    lLM = cutLowMedian(lEMG,lLM,lminT,params.fs);
    rLM = cutLowMedian(rdata,rLM,rminT,params.fs);    
end

% Here is where things diverge if the user specifies 'separate_legs'
if sep_legs == 0
    % calculate PLM candidates by combining the legs
    CLM = combined_candidates(rLM,lLM,apnea_data,arousal_data,start_time,params);
else
    % get CLM from each leg seperately
    lCLM = separate_candidates(lLM,apnea_data,arousal_data,start_time,params);
    rCLM = separate_candidates(rLM,apnea_data,arousal_data,start_time,params);
end

end



