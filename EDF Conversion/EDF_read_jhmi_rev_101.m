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

