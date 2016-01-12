function [ ProtocolName, PSGid, Visit, Night, Repeat, Date ] = CISRE_Naming_Convention_From_Folder( RecordingFolderName )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here


findComma = strfind(RecordingFolderName, ',');
findUnderScore = strfind(RecordingFolderName, '_V');
findDash = strfind(RecordingFolderName, ' - ');
find_ID_VN = RecordingFolderName(findComma + 1 : findDash);
find_ID_VN_find_N = strfind(RecordingFolderName(findUnderScore:end), 'N');


ProtocolName = RecordingFolderName(1 : findComma - 1);
PSGid = RecordingFolderName(findComma + 2 : findUnderScore - 1);
Visit = RecordingFolderName(findUnderScore+2 : findUnderScore+find_ID_VN_find_N-2);
Night = RecordingFolderName(findUnderScore+find_ID_VN_find_N:findDash);
Repeat = NaN;
Date = NaN;

end

