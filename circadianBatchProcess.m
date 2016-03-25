function [ measures ] = circadianBatchProcess()
% outputs array of circadian measures for all patients in file 
%   

bigdir = dir('/Users/lesliebruni/Desktop/Research /Glutamate Study') % Just night 2 for now...
dirlength =  length({bigdir.name})-2;

measures = cell(dirlength,2); %initialize measures array 

for i = 3:dirlength+2
    
    % Load the matlab variable
    patientID = bigdir(i).name(9:19);
    load(['/Users/lesliebruni/Desktop/Research /Glutamate Study/' bigdir(i).name '/' patientID '.mat']);
    
    [~,~,~,~,~,~,PLMt,epochStage,~,~,...
    ~] = minifullRunComboScript(i); %get the PLMt and epochstage data needed for getTRT

    [ TRT, PLMSt ] = getTRT( epochStage, PLMt, 500 ); %get TRT and PLMSt needed for circadian
    
    [ ~, circMeasure ] = circadian( PLMSt, 120, 500 , TRT); %obtain the circadian measure for that patient 
    
   
    measures{i, 1} = circMeasure;
    measures{i, 2} = patientID;
    
    clearvars -except bigdir dirlength i
end % end for loop


end

