%% Wrap data from EDF files and other attributes in a Matlab struct
% Generic_Convert
% 
% An improvement on Allen_Ebm_2_Matlab that does not require strict CISRE
% naming conventions to convert a whole directory of subjects. The user
% must modify ProtocolDIR and modDateAfter according to their needs, then
% run the program. Some required folder organization, which will be
% described in detail in a separate file.
% 
%
% NOTES: Text file time format: YYYY-MM-DDTHH:MM:SS.LLLLLL (L = fractions)
%
% MODIFIED: Patrick 15Aug19 to add centisecond precision
% MODIFIED: Patrick 16Jan1 to begin generalization process

% This is a test environment
clear all; close all; fclose('all'); clc;
tic

% ProtocolDIR is the path to the directory containing the subject folders.
% Must end in '/'
ProtocolDIR = 'Y:/Misc subjects/';                   %
modDateAfter = '13-Jan-2016 5:03:00'; %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

listPSGFolders = dir(ProtocolDIR);
for i = 1 : numel(listPSGFolders)
    
    % Subdirectory name cannot start with '.'
    % Subdirectory must be a directory
    if listPSGFolders(i,1).name(1) ~= '.' && isdir([ProtocolDIR listPSGFolders(i,1).name])
        
        % Only look at folders created after a certain date (may change)
        if (datenum(listPSGFolders(i,1).date) > datenum(modDateAfter))
            RecordingFolderName = listPSGFolders(i,1).name;
            curdir = [ProtocolDIR RecordingFolderName '/'];
            
            % The hypnogram file just needs to contain 'SleepStage'            
            sleep_name = dir([curdir '*SleepStage*']);
            fid2 = fopen([curdir sleep_name(1).name]);                
            fprintf('EDF 2 Matlab conversion: \n\tFolder = %s\n', RecordingFolderName);               
            if fid2 > 0
                
                % IMPORTANT: hypnogram needs 14 headerlines
                EventData = textscan(fid2, '%s%s%s%s%s', 'Headerlines', 14);
                fclose(fid2);
                RKstart = EventData{1,1}{1,1};                                
                HypnogramStart = [RKstart(1:10) ' ' RKstart(12:22)];
                Staging = EventData{1,2}(1:end);
                Staging_Int = nan(size(Staging));
                for i = 1 : size(Staging,1)
                    switch Staging{i,1}(8)
                        case '0'
                            Staging_Int(i,1) = 0;
                        case '1'
                            Staging_Int(i,1) = 1;
                        case '2'
                            Staging_Int(i,1) = 2;
                        case '3'
                            Staging_Int(i,1) = 3;
                        case 'E'
                            Staging_Int(i,1) = 5;
                    end
                end
            end
            
            % EDF file MUST be called 'Traces.edf'
            [EDF] = EDF_read_jhmi_rev_101([curdir 'Traces.edf']);

            % Extract all channels
            EDFStart = ['20' EDF.date(7:8) '-' EDF.date(4:5) '-' EDF.date(1:2) ' ' EDF.time(1:2) ':' EDF.time(4:5) ':' EDF.time(7:8)];
            EDF.RecordingFolderName = RecordingFolderName;
            [ProtocolName, PSGid, Visit, Night, Repeat, Date] = CISRE_Naming_Convention_From_Folder(RecordingFolderName);
            EDF.CISRE_ProtocolName = ProtocolName;
            EDF.CISRE_PSGid = PSGid;
            EDF.CISRE_Visit = Visit;
            EDF.CISRE_Night = Night;
            EDF.CISRE_HypnogramStart = HypnogramStart;
            EDF.CISRE_Hypnogram = Staging_Int;
            EDF.EDFdirectory = curdir;
            EDF.EDFStart = EDFStart;
            EDF.EDFfileName = 'Traces.edf';
            EDF_DTvec = datenum(EDFStart);          
            Hypno_DTvec = datenum(HypnogramStart);
            [yx,mx,dx,hx,mix,sx]=datevec(Hypno_DTvec - EDF_DTvec);
            EDFStart2HypnoInSec = DatevecInSec(yx,mx,dx,hx,mix,sx);
            EDF.EDFStart2HypnoInSec = EDFStart2HypnoInSec;
            
            % Load the text files for apnea and arousal events (Added by TonyH)
            % Colunms correspond to: time,event,duration                        
            ap_name = dir([curdir '*Apnea*']);
            fidAp = fopen([curdir ap_name(1).name]);            
            if fidAp > 0
                EventDataAp = textscan(fidAp, '%s%s%s', 'Headerlines', 20); %%Skip 20 lines
                fclose(fidAp);
                [M,~]=size(EventDataAp{1,1});
                EventDataAp=[EventDataAp{1,1} EventDataAp{1,2} EventDataAp{1,3}];%%Puts all 3 arrays into the same matrix
                %Extracts the date+military time (yyyy-mm-dd hh:mm:ss)
                for ii=1:M
                    EventDataAp{ii,1} = [EventDataAp{ii,1}(1:10), ' ',EventDataAp{ii,1}(12:22)];
                end
            else % Make empty array if none exists                
                EventDataAp=num2cell(zeros(1,3));
            end
            EDF.CISRE_Apnea=EventDataAp;
            
            ar_name = dir([curdir '*Arousal*']);
            fidAr = fopen([curdir ar_name(1).name]);             
            if fidAr > 0
                EventDataAr = textscan(fidAr, '%s%s%s', 'Headerlines', 18); %%Skip 18 lines
                fclose(fidAr);
                [M,~]=size(EventDataAr{1,1});
                EventDataAr=[EventDataAr{1,1} EventDataAr{1,2} EventDataAr{1,3}]; %%Puts all 3 arrays into the same matrix
                %Extracts the date+military time (yyyy-mm-dd hh:mm:ss)
                for ii=1:M
                    EventDataAr{ii,1} = [EventDataAr{ii,1}(1:10),' ',EventDataAr{ii,1}(12:22)];
                end
            else
                EventDataAr=num2cell(zeros(1,3));
            end
            EDF.CISRE_Arousal=EventDataAr;
            
            % Save the .mat file
            j = strfind(curdir, '/');
            ShortName = curdir(j(end-1)+1:j(end)-1);
            ShortName = strsplit(ShortName);
            ShortName = char(ShortName(2));
            assignin('base', ShortName, EDF);
            save([curdir ShortName '.mat'],ShortName,'-v7.3');
            fprintf('\tTime = %4.2f\n',toc)
            
            
            clearvars -except ProtocolDIR modDateAfter listPSGFolders i
            
        end
    end
end





fprintf('Total Time = %4.2f\n',toc)


