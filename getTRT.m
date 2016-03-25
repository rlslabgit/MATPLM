function [ TRT, PLMSt ] = getTRT( epochStage, PLMt, fs )
%takes in epochStage and PLMt and outputs TRT and PLMSt
%   TRT = total rest time from epoch Stage, PLMSt = only extracting the
%   rows from sleep in PLMt

TRT = size(epochStage, 1) * 30 * fs;
PLMSt = PLMt(PLMt(:,6) > 0, :);



end


