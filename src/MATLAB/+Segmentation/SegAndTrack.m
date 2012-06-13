% SegAndTrack.m - Spawns segmentation and tracking routines to identify and
% track cells in a sequence of microscope images.

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

function errStatus = SegAndTrack()
    global CONSTANTS
    
    tSeg = 0;
    tTrack = 0;

    % Modified 
    errStatus = 1;
    
    if (exist('LEVerSettings.mat','file')~=0)
            load('LEVerSettings.mat');
    else
        settings.matFilePath = '.\';
    end

    [settings.matFile,settings.matFilePath,FilterIndex] = uiputfile('.mat','Save edits',...
        [CONSTANTS.imageDatasetName '_LEVer.mat']);

    if(~FilterIndex)
        return;
    end

    % 
    save('LEVerSettings.mat','settings');
    
    numProcessors = getenv('Number_of_processors');
    numProcessors = str2double(numProcessors);
    if(isempty(numProcessors) || isnan(numProcessors) || numProcessors < 4)
        numProcessors = 4;
    end
    
    if (strcmp(CONSTANTS.cellType,'Hemato'))
        Segmentation.HematoSegmentation(1.0);
        Tracker.ExternalRetrack();
        errStatus = 0;
    else
        [errStatus tSeg tTrack] = Segmentation.SegAndTrackDataset(CONSTANTS.rootImageFolder(1:end-1), CONSTANTS.imageDatasetName, CONSTANTS.imageAlpha, CONSTANTS.imageSignificantDigits, numProcessors);
    end
    if ( errStatus > 0 )
        return;
    end
    
    UI.SaveData(1);
    
    UI.InitializeFigures();
    
    Error.LogAction('Segmentation time - Tracking time',tSeg,tTrack);
end