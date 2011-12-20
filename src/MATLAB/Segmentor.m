% Segmentor.m - Cell image segmentation algorithm.
% Segmentor is to be run as a seperate compiled function for parallel
% processing.  It will process tLength-tStart amount of images.  Call this
% function for the number of processors on the machine.

% mcc -o Segmentor -m Segmentor.m

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     Copyright 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%     This file is part of LEVer - the tool for stem cell lineaging. See
%     https://pantherfile.uwm.edu/cohena/www/LEVer.html for details
% 
%     LEVer is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
%     LEVer is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
% 
%     You should have received a copy of the GNU General Public License
%     along with LEVer in file "gnu gpl v3.txt".  If not, see 
%     <http://www.gnu.org/licenses/>.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [objs features] = Segmentor(tStart,tStep,tEnd,rootImageFolder,datasetName,imageAlpha,imageSignificantDigits)
    
objs=[];
features = [];
if(ischar(tStart)),tStart = str2double(tStart);end
if(ischar(tStep)),tStep = str2double(tStep);end
if(ischar(tEnd)),tEnd = str2double(tEnd);end
if(ischar(imageAlpha)),imageAlpha = str2double(imageAlpha);end
if(ischar(imageSignificantDigits)),imageSignificantDigits = str2double(imageSignificantDigits);end

numImages = tEnd/tStep;

for t = tStart:tStep:tEnd
    switch imageSignificantDigits
        case 3
            frameT = num2str(t,'%03d');
        case 4
            frameT = num2str(t,'%04d');
        case 5
            frameT = num2str(t,'%05d');
        case 6
            frameT = num2str(t,'%06d');
    end
    fname=[rootImageFolder '\' datasetName '_t' frameT '.TIF'];
    if(isempty(dir(fname))),continue,end
    
    fprintf('%d%%...',floor(floor(t/tStep)/numImages*100));
    
    [im map]=imread(fname);
    
    [frmObjs frmFeatures] = FrameSegmentor(im, t, imageAlpha);
    objs = [objs frmObjs];
    features = [features frmFeatures];
end

fileName = ['.\segmentationData\objs_' num2str(tStart) '.mat'];
if(isempty(dir('.\segmentationData'))),system('mkdir .\segmentationData');end
save(fileName,'objs','features');

fprintf('\tDone\n');
end
