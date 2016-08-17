function [EDF_sup] = brainRT_prep_rev1(all_events,filepath)
%% [EDF_sup] = brainRT_prep(all_events)
% Convert Imad Ghorayeb's files from BrainRT to Matlab. Notice this is very
% specific to his format, because it relies on the particular codes for
% events. Everything in apnea/arousal arrays is a string. Hypnogram should
% be in the form 'yyyy-mm-dd HH:MM:SS.FFF' when finished.

% [EDF_sup] = EDF_read_jhmi_rev_101(); % open window to pick file
[EDF_sup] = EDF_read_jhmi_rev_101(filepath); % open window to pick file

% trim off all the unneeded channels so it doesn't take 10 mins to load
i = 1;

while i <= size(EDF_sup.Signals,2)
    if ~findWanted(EDF_sup.Signals(i).label)
        EDF_sup.Signals(:,i) = [];
    else
        i = i + 1;
    end    
end

lbls = extractfield(EDF_sup.Signals,'label');
idx = find(not(cellfun('isempty', strfind(lbls,'JbG'))));
EDF_sup.Signals(idx).label = 'Left Leg';
idx = find(not(cellfun('isempty', strfind(lbls,'JbD'))));
EDF_sup.Signals(idx).label = 'Right Leg';
idx = find(not(cellfun('isempty', strfind(lbls,'ECG'))));
EDF_sup.Signals(idx).label = 'EKG';

% remove things before 'lights off'
codes = cell2mat(all_events(:,1)); % extract event codes
lights_off = find(codes == 139);
last_stage = find(codes(1:lights_off) == 128);
last_stage = last_stage(end);

% align start times
all_events{last_stage, 4} = all_events{lights_off, 4};
all_events(lights_off, :) = all_events(last_stage, :);
all_events = all_events(lights_off:end,:);

codes = cell2mat(all_events(:,1)); % extract event codes
hypnogram = all_events(codes == 128,[2,4,5]); % 128 is code for hypnogram
hypnogram_start = hypnogram{1,2};

% convert to our sleep stage format
stage_codes = cell2mat(hypnogram(:,1));
hypnogram(stage_codes == 2, 1) = {0};
hypnogram(stage_codes == 301, 1) = {1};
hypnogram(stage_codes == 302, 1) = {2};
hypnogram(stage_codes == 303, 1) = {3};
hypnogram(stage_codes == 304, 1) = {4};
hypnogram(stage_codes == 201, 1) = {5};

% date format in the xml file
formatIn = 'yyyy-mm-ddTHH:MM:SS.FFF';
for i = 1:size(hypnogram,1)
    N1 = datevec(char(hypnogram{i,2}),formatIn); % start time
    N2 = datevec(char(hypnogram{i,3}),formatIn); % end time
    hypnogram{i,3} = etime(N2,N1); % replace end time with duration in secs
end

% now make our simple hypnogram file
simp_hyp = [];
for i = 1:size(hypnogram,1)
    for j = 1:(hypnogram{i,3}/30)
        simp_hyp = [simp_hyp ; hypnogram{i,1}];
    end
end

EDF_sup.CISRE_HypnogramStart = hypnogram_start;
EDF_sup.CISRE_HypnogramStart(11) = ' '; % get rid of the T
EDF_sup.CISRE_Hypnogram = simp_hyp;

% Now we add things like times
EDF_sup.EDFStart = ['20' EDF_sup.date(7:8) '-' EDF_sup.date(4:5) '-'...
    EDF_sup.date(1:2) ' ' EDF_sup.time(1:2) ':' EDF_sup.time(4:5) ':'...
    EDF_sup.time(7:8)];

% Time between start of recording and start of scoring
EDF_DTvec = datenum(EDF_sup.EDFStart); % fine, its default form
Hypno_DTvec = datenum(hypnogram_start,formatIn);
EDF_sup.EDFStart2HypnoInSec = etime(datevec(Hypno_DTvec),datevec(EDF_DTvec));

% TODO: Apnea and Arousal from events file?
EDF_sup.CISRE_Apnea = num2cell(zeros(1,3));

% Add arousal data to the structure
arousals = all_events(codes == 135,:);
for i = 1:size(arousals,1)
    arousals{i,1} = arousals{i,4};
    arousals{i,2} = 'AROUSAL';
    arousals{i,3} = num2str(etime(datevec(arousals{i,5},formatIn),...
        datevec(arousals{i,4},formatIn)));
    arousals{i,1}(11) = ' '; % remove T
end

if isempty(arousals)
    EDF_sup.CISRE_Arousal = num2cell(zeros(1,3));
else
    EDF_sup.CISRE_Arousal = arousals(:,1:3);
end

% Add apnea data to the structure. We only care about 129-3 and 129-2,
% which are the codes for obstructive/central apnea (ignore hypopnea I
% think)
apneas = all_events(codes == 129,:);
apneas = apneas(cell2mat(apneas(:,2)) == 2 | cell2mat(apneas(:,2)) == 3,:);

for i = 1:size(apneas,1)
    apneas{i,1} = apneas{i,4};
    
    if apneas{i,2} == 3
        apneas{i,2} = 'APNEA-OBSTRUCTIVE';
    else
        apneas{i,2} = 'APNEA-CENTRAL';
    end
    apneas{i,3} = num2str(etime(datevec(apneas{i,5},formatIn),...
        datevec(apneas{i,4},formatIn)));
    apneas{i,1}(11) = ' '; % remove T
end

if isempty(apneas)
    EDF_sup.CISRE_Apnea = num2cell(zeros(1,3));
else
    EDF_sup.CISRE_Apnea = apneas(:,1:3);
end

end

function [wanted] = findWanted(sig_name)

l = strfind(sig_name,'JbG');
r = strfind(sig_name, 'JbD');
c = strfind(sig_name, 'ECG');

if ~isempty(l) || ~isempty(r) || ~isempty(c)
    wanted = true;
else
    wanted = false;
end

end

function [EDF] = EDF_read_jhmi_rev_101(FilePath)
% NAME: EDFRead
% FACILITY: EDF and Matlab
% SEARCH: 
% LANGUAGE: Matlab
% AUTHOR: Francis P. Sgambati
% INSTITUTION: The Johns Hopkins University
% DIVISION: School of Medicine  
% DEPARTMENT: Medicine
% CENTER of Interdisiplinary Sleep Research and Education
% CREATED: January 2014
%
% ARGUMENTS: EDF file exported from RemLogic containing an unknown number
% of channels
%
% RETURNS: A Matlab file containing a structure of the EDF data.
%
% MODIFIED:
%
% DESCRIPTION: 

%% Read and load EDF traces from RemLogic%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ( nargin < 1 ) | size( FilePath ) == 0
  [ file, path ] = uigetfile('*.edf', 'Open an EDF File:' );
  if ( file == 0 )
    error( ERROR_CANCEL );
  end;
  FilePath = [ path, file ];
end;

fid=fopen(FilePath);
EDF = struct;
% HEADER RECORD
% 8 ascii : version of this data format (0)
EDF.version=str2double(char(fread(fid,8)'));
% 80 ascii : local patient identification
EDF.patientID=fread(fid,80,'*char')';
% 80 ascii : local recording identification
EDF.recordID=fread(fid,80,'*char')';
% 8 ascii : startdate of recording (dd.mm.yy)
EDF.date=fread(fid,8,'*char')';
% 8 ascii : starttime of recording (hh.mm.ss)
EDF.time=fread(fid,8,'*char')';
EDF.dateTime = ['20' EDF.date(7:8) '-' EDF.date(4:5) '-' EDF.date(1:2) ' ' EDF.time(1:2) ':' EDF.time(4:5) ':' EDF.time(7:8)];
% 8 ascii : number of bytes in header record
EDF.byte_header=str2double(fread(fid,[1 8],'*char')');
% 44 ascii : reserved
EDF.reserved1=fread(fid,44,'*char')';
% 8 ascii : number of data records (-1 if unknown)
EDF.nRecords=str2double(fread(fid,8,'*char')');
% 8 ascii : duration of a data record, in seconds
EDF.tRecordSecs=str2double(fread(fid,8,'*char')');
% 4 ascii : number of signals (ns) in data record
EDF.ns=str2double(fread(fid,4,'*char')');
% ns * 16 ascii : ns * label (e.g. EEG FpzCz or Body temp)
for i=1:EDF.ns
    recordLabel{i} = fread(fid,16,'*char')';
end
% ns * 80 ascii : ns * transducer type (e.g. AgAgCl electrode)
for i = 1:EDF.ns
    transducer{i} = fread(fid,80,'*char')';
end  
% ns * 8 ascii : ns * physical dimension (e.g. uV or degreeC)
for i = 1:EDF.ns
    units{i} = fread(fid,8,'*char')';
end
% ns * 8 ascii : ns * physical minimum (e.g. -500 or 34)
for i=1:EDF.ns
    physicalMin(i) = str2double(fread(fid,8,'*char')');
end
% ns * 8 ascii : ns * physical maximum (e.g. 500 or 40)
for i=1:EDF.ns
    physicalMax(i) = str2double(fread(fid,8,'*char')');
end
% ns * 8 ascii : ns * digital minimum (e.g. -2048)
for i=1:EDF.ns
    digitalMin(i) = str2double(fread(fid,8,'*char')');
end
% ns * 8 ascii : ns * digital maximum (e.g. 2047)
for i=1:EDF.ns
    digitalMax(i) = str2double(fread(fid,8,'*char')');
end
% ns * 80 ascii : ns * prefiltering (e.g. HP:0.1Hz LP:75Hz)
for i=1:EDF.ns
    preFilterings{i} = fread(fid,80,'*char')';
end
% ns * 8 ascii : ns * nr of samples in each data record
for i = 1:EDF.ns
    samples(i) = str2double(fread(fid,8,'*char')');
end
% ns * 32 ascii : ns * reserved
for i = 1:EDF.ns
    reserved2 = fread(fid,32,'*char')';
end

scaleFactor = (physicalMax - physicalMin)./(digitalMax - digitalMin);
    offset = physicalMax - scaleFactor .* digitalMax;
    
%% Extract all channels %%%%%%%
% Create a nested structure for channel/signal specific data/info
EDF.Signals = [];
for i = 1 : EDF.ns
    EDF.Signals(1,i).label = recordLabel{1,i};
    EDF.Signals(1,i).transducer = transducer{1,i};
    EDF.Signals(1,i).physicalMin = physicalMin(i);
    EDF.Signals(1,i).physicalMax = physicalMax(i);
    EDF.Signals(1,i).digitalMin = digitalMin(i);
    EDF.Signals(1,i).digitalMax = digitalMax(i);
    EDF.Signals(1,i).preFilterings = preFilterings{1,i};
    fSamplingRate = samples(i) / EDF.tRecordSecs;
        EDF.Signals(1,i).frq = fSamplingRate;
    EDF.Signals(1,i).unit = units{1,i};
    EDF.Signals(1,i).data = nan(EDF.nRecords * samples(i),1);
    EDF.Signals(1,i).traceIndex = 1;
    EDF.Signals(1,i).ScalingFactorApplied = ['data * ' num2str(scaleFactor(i)) ' + ' num2str(offset(i))];
end
% Write data into vecotrs
for ii = 1 : EDF.nRecords-1
    for jj = 1 : EDF.ns
        try
            tmp_read=fread(fid,samples(jj),'int16') * scaleFactor(jj) + offset(jj);
            EDF.Signals(1,jj).data( EDF.Signals(1,jj).traceIndex : ...
                EDF.Signals(1,jj).traceIndex + samples(jj)-1) ...
                = tmp_read; 
            % Write a temp index for where the trace index or cursor remains
            EDF.Signals(1,jj).traceIndex = ...
                EDF.Signals(1,jj).traceIndex + samples(jj);
        catch err
            break
            %if not (mod(i,10000))
            %    err.
            %    fprintf('ERR: nRecords = %f\n\tns = %f\n',ii,jj)
            %end
        end
    end
end
end

