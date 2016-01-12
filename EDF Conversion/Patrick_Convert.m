% NAME: Allen_Ebm_2_Matlab
% FACILITY: EDF and Matlab
% SEARCH: 
% LANGUAGE: Matlab
% AUTHOR: Francis P. Sgambati
% INSTITUTION: The Johns Hopkins University
% DIVISION: School of Medicine  
% DEPARTMENT: Pulmonary and Critical Care
% CENTER of Interdisiplinary Sleep Research and Education (CISRE)
% CREATED: January 2014
%
% ARGUMENTS: EDF file exported from RemLogic containing an unknown number
% of channels
%
% RETURNS: A Matlab file containing a structure of the EDF data.
%
% MODIFIED: September, 2014
%
% DESCRIPTION: This program uses EDF_read_jhmi_rev_101 to convert an EDF
% file into a Matlab file.  This particular script uses rules created by
% CISRE which creates a unique set of idendifiers.  Most notably it now is
% able to accomodate additional "SIT" recordings.
%
%
% MODIFIED: Patrick 8/19 to add centisecond precision

%% This is a test environment
clear all; close all; fclose('all'); clc;
tic

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ProtocolDIR = 'Y:\';                   %
modDateAfter = '17-Aug-2015 9:03:00'; %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

listPSGFolders = dir(ProtocolDIR);
for i = 1 : numel(listPSGFolders)
    if  strcmp(listPSGFolders(i,1).name, '.')~=1 & strcmp(listPSGFolders(i,1).name,'..')~=1 & strcmp(listPSGFolders(i,1).name,'.DS_Store')~=1
        
        if (datenum(listPSGFolders(i,1).date) > datenum(modDateAfter))
            RecordingFolderName = listPSGFolders(i,1).name;
            curdir = [ProtocolDIR RecordingFolderName '\'];

            if strcmp(RecordingFolderName(9:12),'mSIT')
                fid2 = -99;
                ShortName = strrep(RecordingFolderName(9:24), ' - ', '_');
            else
                ShortName = RecordingFolderName(9:19);
                fid2 = fopen([curdir ShortName ' AidRLS-Events SleepStage.txt']);
            end
            fprintf('EDF 2 Matlab conversion: \n\tFolder = %s\n\tShortName = %s\n', RecordingFolderName, ShortName);        
            %% Load the text file for the hypnogram data

            if fid2 > 0 
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
            elseif fid2 == -99
                Staging_Int = nan(1,8);
                for ii = 5 : 8
                    
                    fid3 = fopen([curdir ShortName ' AidRLS-SIT' num2str(ii) '.txt']);
                    if fid3 > 1 
                        %Staging_Int = 0;
                        %HypnogramStart = '1-Jan-2000 00:00:00';
                        EventData = textscan(fid3, '%s%s%s%s%s', 'Headerlines', 14);
                        fclose(fid3);
                        RKstart = EventData{1,1}{1,1};
                        HypnogramStart{ii} = [RKstart(1:10) ' ' RKstart(12:19)];
                        Staging = EventData{1,2}(1:end);
                        for i = 1 : size(Staging,1)
                            switch Staging{i,1}(8)
                                case '0'
                                    Staging_Int(i,ii) = 0;
                                case '1'
                                    Staging_Int(i,ii) = 1;
                                case '2'
                                    Staging_Int(i,ii) = 2;
                                case '3'
                                    Staging_Int(i,ii) = 3;
                                case 'E'
                                    Staging_Int(i,ii) = 5;
                            end
                        end
                    end
                end
            else
                uiwait(msgbox(['Text file not found for nap: ' num2str(ii)],'Title','modal'))
            end

            %% Determine path of the EDF file
            edf_path = curdir;
            edf_fileName = 'Traces.edf';
            edf_FulFile = fullfile(edf_path, edf_fileName);
            [EDF] = EDF_read_jhmi_rev_101_Patrick(edf_FulFile);

            %% Extract all channels %%%%%%%
            EDFStart = ['20' EDF.date(7:8) '-' EDF.date(4:5) '-' EDF.date(1:2) ' ' EDF.time(1:2) ':' EDF.time(4:5) ':' EDF.time(7:8)];
            EDF.RecordingFolderName = RecordingFolderName;
            [ProtocolName, PSGid, Visit, Night, Repeat, Date] = CISRE_Naming_Convention_From_Folder(RecordingFolderName);
            EDF.CISRE_ProtocolName = ProtocolName;
            EDF.CISRE_PSGid = PSGid;
            EDF.CISRE_Visit = Visit;
            EDF.CISRE_Night = Night;
            %EDF.ProtocolName = ProtocolName;
            %EDF.ProtocolName = ProtocolName;

            if fid2 == -99
                for ii = 5 : 8
                    EDF.CISRE_HypnogramStart(ii) = HypnogramStart(ii);
                    EDF.CISRE_Hypnogram(:,ii) = Staging_Int(:,ii);
                end
            else
                EDF.CISRE_HypnogramStart = HypnogramStart;
                EDF.CISRE_Hypnogram = Staging_Int;
            end

            EDF.EDFdirectory = edf_path;
            EDF.EDFStart = EDFStart;
            EDF.EDFfileName = edf_fileName;

            EDF_DTvec = datenum(EDFStart);
            if fid2 == -99
                for ii = 5 : 8
                    if cellfun('length',HypnogramStart(ii)) > 1
                        Hypno_DTvec(ii) = datenum(HypnogramStart(ii));
                        [yx,mx,dx,hx,mix,sx]=datevec(Hypno_DTvec(ii) - EDF_DTvec);
                        EDFStart2HypnoInSec(ii) = DatevecInSec(yx,mx,dx,hx,mix,sx);
                        EDF.EDFStart2HypnoInSec(ii) = EDFStart2HypnoInSec(ii);
                    end
                end
            else
                Hypno_DTvec = datenum(HypnogramStart);
                [yx,mx,dx,hx,mix,sx]=datevec(Hypno_DTvec - EDF_DTvec);
                EDFStart2HypnoInSec = DatevecInSec(yx,mx,dx,hx,mix,sx);
                EDF.EDFStart2HypnoInSec = EDFStart2HypnoInSec;                
            end
            %% Load the text files for apnea and arousal events (Added by TonyH)
            % Colunms correspond to: time,event,duration
            if ~strcmp(RecordingFolderName(9:12),'mSIT') %Making sure it is an overnight trial
                fidAp=fopen([curdir ShortName ' AidRLS-Events Apnea.txt']); 
                if fidAp ~=-1
                    EventDataAp = textscan(fidAp, '%s%s%s', 'Headerlines', 20); %%Skip 20 lines
                    fclose(fidAp);
                    [M,~]=size(EventDataAp{1,1});
                    EventDataAp=[EventDataAp{1,1} EventDataAp{1,2} EventDataAp{1,3}];%%Puts all 3 arrays into the same matrix
                    %Extracts the date+military time (yyyy-mm-dd hh:mm:ss)
                    for ii=1:M
                        EventDataAp{ii,1} = [EventDataAp{ii,1}(1:10), ' ',EventDataAp{ii,1}(12:22)];
                    end
                else
                    EventDataAp=num2cell(zeros(1,3));
                end
                EDF.CISRE_Apnea=EventDataAp;
                
                fidAr=fopen([curdir ShortName ' AidRLS-Events Arousal.txt']); 
                if fidAr ~= -1
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
            end
            %% Save the .mat file
            %eval('ShortName = EDF');
            if fid2 == -99
                ShortName = strrep(ShortName,'-','_');
            end
            assignin('base', ShortName, EDF);
            save([curdir ShortName '.mat'],ShortName,'-v7.3');
            fprintf('\tTime = %4.2f\n',toc)
            eval(['clear ' ShortName])
            clear Date EDF ShortName EDFStart EDFStart2HypnoInSec EDF_DTvec HypnogramStart Night PSGid ProtocolName RKstart 
            clear RecordingFolderName Repeat ShortName Staging Staging_Int Visit ans curdir dx
            clear edf_FulFile edf_fileName edf_path hx i mix mx sx yx
            clear EventData Hypno_DTvec
            clear EventDataAp EventDataAr M
        end
    end
end





fprintf('Total Time = %4.2f\n',toc)


