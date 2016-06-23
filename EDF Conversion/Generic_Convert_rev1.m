function Generic_Convert_rev1()
%% Wrap data from EDF files and other attributes in a Matlab struct
% Generic_Convert
%
% An improvement on Allen_Ebm_2_Matlab that does not require strict CISRE
% naming conventions to convert a whole directory of subjects. The user
% must modify ProtocolDIR and modDateAfter according to their needs, then
% run the program. Some required folder organization, which will be
% described in detail in a separate file.
%
% Author: Frank Sgambati - JHU CISRE
%
% NOTES: Text file time format: YYYY-MM-DDTHH:MM:SS.LLLLLL (L = fractions)
%
% MODIFIED: Patrick 19Aug15 to add centisecond precision
% MODIFIED: Patrick 1Jan16 to begin generalization process
% MODIFIED: Patrick 16Jun16 for even more generalization
tic

% ProtocolDIR is the path to the directory containing the subject folders.
% Must end in '/'
ProtocolDIR = 'D:/tDCS Data/';    %
modDateAfter = '13-Jan-2016 5:03:00'; %
study_id = 'tDCS';

fd_format = 'yyyy-mm-ddTHH:MM:SS.fff';
new_format = 'yyyy-mm-dd HH:MM:SS.fff';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

cd(ProtocolDIR);
listPSGFolders = dir([study_id '*']);

for i = 1 : numel(listPSGFolders)
    % Only look at folders created after a certain date (may change)
    if (datenum(listPSGFolders(i,1).date) > datenum(modDateAfter))
        RecordingFolderName = listPSGFolders(i,1).name;
        cd(RecordingFolderName)
        
        fprintf('EDF 2 Matlab conversion: \n\tFolder = %s\n', RecordingFolderName);
        
        % It's going to use the first edf file in the folder...just put one
        % in there to keep it simple
        edf = dir('*.edf');
        [EDF] = EDF_read_jhmi_rev_101(edf(1).name);
        EDF.EDFStart = EDF.dateTime;
        
        % trim off all the unneeded channels so it doesn't take 10 mins to load
        ii = 1;
        while ii <= size(EDF.Signals,2)
            if ~findWanted(EDF.Signals(ii).label)
                EDF.Signals(:,ii) = [];
            else
                ii = ii + 1;
            end
        end
        
        f = dir('*SleepStage*');
        if size(f,1) > 0
            % Hypnogram filename should contain the word 'SleepStage'
            f = dir('*SleepStage*'); f = f(1).name;
            T = readtable(f,'headerlines',14,'Delimiter','\t');
            
            d = char(T.Var1(1));
            EDF(1).CISRE_HypnogramStart = datestr(datenum(d,fd_format),new_format);
            T = T.Var2;
            
            a = zeros(size(T,1),1);
            a(~cellfun('isempty', strfind(T,'1'))) = 1;
            a(~cellfun('isempty', strfind(T,'2'))) = 2;
            a(~cellfun('isempty', strfind(T,'3'))) = 3;
            a(~cellfun('isempty', strfind(T,'4'))) = 4;
            a(~cellfun('isempty', strfind(T,'REM'))) = 5;
            
            EDF.CISRE_Hypnogram = a;
            EDF.EDFStart2HypnoInSec = etime(datevec(EDF.CISRE_HypnogramStart),...
                datevec(EDF.EDFStart));
        else
            warning('Subject has no hypnogram...skipping');
            continue;
        end
        
        f = dir('*Arousal*');
        if size(f,1) > 0
            % Arousal filename should contain the word 'Arousal'
            f = f(1).name;
            T = readtable(f,'headerlines',18,'Delimiter','\t');
            T = table2cell(T);
            if size(T,1) > 0
                T(:,1) = cellstr(datestr(datenum(T(:,1),fd_format),new_format));
                EDF.CISRE_Arousal = T;
            else
                EDF.CISRE_Arousal = cell(0);
            end
        else
            warning('No arousal data available')
            EDF.CISRE_Arousal = cell(0);
        end
        
        f = dir('*Apnea*');
        if size(f,1) > 0
            % Apnea filename should contain the word 'Apnea'
            f = f(1).name;
            T = readtable(f,'headerlines',20,'Delimiter','\t');
            T = table2cell(T);
            if size(T,1) > 0
                T(:,1) = cellstr(datestr(datenum(T(:,1),fd_format),new_format));
                EDF.CISRE_Apnea = T;
            else
                EDF.CISRE_Apnea = cell(0);
            end
        else
            warning('No arousal data available')
            EDF.CISRE_Apnea = cell(0);
        end
        
        EDF.EDFdirectory = pwd;
        EDF.EDFfileName = edf(1).name;
        EDF.RecordingFolderName = RecordingFolderName;
        
        
        % Save the .mat file
        save('EDF_struct.mat', 'EDF');
        fprintf('\tTime = %4.2f\n',toc)
                
        cd(ProtocolDIR);
    end
    
end

fprintf('Total Time = %4.2f\n',toc)

end

function [wanted] = findWanted(sig_name)

l = strfind(sig_name,'Left');
r = strfind(sig_name, 'Right');
c = strfind(sig_name, 'EKG');

if ~isempty(l) || ~isempty(r) || ~isempty(c)
    wanted = true;
else
    wanted = false;
end

end


