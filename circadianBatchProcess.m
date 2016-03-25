function [ measures ] = circadianBatchProcess()
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

bigdir = dir('Y:\AidRLS*V1N2*'); % Just night 2 for now...
dirlength =  length(bigdir);

measures = cell(dirlength,2);

for i = 1:dirlength
    
    % Load the matlab variable
    patientID = bigdir(i).name(9:19);
    load(['Y:\' bigdir(i).name '\' patientID '.mat']);
    
    [~,~,~,~,~,~,PLMt,epochStage,~,~,...
    ~] = minifullRunComboScript(i);

    [ TRT, PLMSt ] = getTRT( epochStage, PLMt, 500 );
    
    [ ~, circMeasure ] = circadian( PLMSt, 120, 500 , TRT);
    
    measures{i, 1} = circMeasure;
    measures{i, 2} = patientID;
    
    clearvars -except bigdir dirlength i
end % end for loop


end

