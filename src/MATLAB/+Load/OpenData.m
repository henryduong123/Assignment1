% OpenData.m - 
% Opens the data file either from a previous state of LEVer or from tracking
% results.  If the latter, the data will be converted to LEVer's data scheme
% and save out to a new file.

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

function opened = OpenData()

global Figures Colors CONSTANTS CellFamilies CellHulls CellFeatures HashedCells Costs GraphEdits CellTracks ConnectedDist CellPhenotypes Log ReplayEditActions SegmentationEdits SegLevels softwareVersion

if(isempty(Figures))
    fprintf('LEVer ver %s\n***DO NOT DISTRIBUTE***\n\n', softwareVersion);
end

if(exist('ColorScheme.mat','file'))
    load 'ColorScheme.mat'
    Colors = colors;
else
    %the lowercase var is saved out where the capital var the one used
    colors = Load.CreateColors();
    Colors = colors;
    save('ColorScheme','colors');
end
    
if (~exist('settings','var') || isempty(settings))
    if (exist('LEVerSettings.mat','file'))
        load('LEVerSettings.mat');
    else
        settings.imagePath = '.\';
        settings.matFilePath = '.\';
    end
end

filterIndexImage = 0;
goodLoad = 0;
opened = 0;

if(~isempty(Figures))
    if(strcmp(get(Figures.cells.menuHandles.saveMenu,'Enable'),'on'))
        choice = questdlg('Save current edits before opening new data?','Closing','Yes','No','Cancel','Cancel');
        switch choice
            case 'Yes'
                UI.SaveData(0);
                set(Figures.cells.menuHandles.saveMenu,'Enable','off');
            case 'Cancel'
                return
            case 'No'
                set(Figures.cells.menuHandles.saveMenu,'Enable','off');
            otherwise
                return
        end
    end
end

% Clear edits when new data set is opened
SegmentationEdits.newHulls = [];
SegmentationEdits.changedHulls = [];

CellFeatures = [];
GraphEdits = [];
SegLevels = [];
ReplayEditActions = [];

oldCONSTANTS = CONSTANTS;

%find the first image
imageFilter = [settings.imagePath '*.TIF'];

sigDigits = 0;
fileName = [];
tryidx = 0;
while ( (sigDigits == 0) || ~exist(fileName,'file') )
    if ( tryidx > 0 )
        fprintf('Image file name not in correct format:%s_t%s.TIF\nPlease choose another...\n',CONSTANTS.datasetName,frameT);
    else
        fprintf('\nSelect first .TIF image...\n\n');
    end

    [settings.imageFile,settings.imagePath,filterIndexImage] = uigetfile(imageFilter,'Open First Image in dataset: ');
    if (filterIndexImage==0)
        CONSTANTS = oldCONSTANTS;
        return
    end

    [sigDigits imageDataset] = Helper.ParseImageName(settings.imageFile);

    CONSTANTS.rootImageFolder = settings.imagePath;

    CONSTANTS.imageDatasetName = imageDataset;
    CONSTANTS.datasetName = imageDataset;
    CONSTANTS.imageSignificantDigits = sigDigits;
    fileName = [CONSTANTS.rootImageFolder imageDataset '_t' Helper.GetDigitString(1) '.TIF'];

    tryidx = tryidx + 1;
end

% while ( isempty(index) || ~exist(fileName,'file') )
%     fprintf('Image file name not in correct format:%s_t%s.TIF\nPlease choose another...\n',CONSTANTS.datasetName,frameT);
%     
%     [settings.imageFile,settings.imagePath,filterIndexImage] = uigetfile(settings.imagePath,'Open First Image');
%     if(filterIndexImage==0)
%         CONSTANTS = oldCONSTANTS;
%         return
%     end
%     index = strfind(imageFile,'t');
%     CONSTANTS.rootImageFolder = [settings.imagePath '\'];
%     imageDataset = imageFile(1:(index(length(index))-2));
%     fileName=[CONSTANTS.rootImageFolder imageDataSet '_t' Helper.GetDigitString(t) '.TIF'];
% end

answer = questdlg('Run Segmentation and Tracking or Use Existing Data?','Data Source','Segment & Track','Existing','Existing');
switch answer
    case 'Segment & Track'
        save('LEVerSettings.mat','settings');
        Load.InitializeConstants();
        Load.UpdateFileVersionString(softwareVersion);
        errOpen = Segmentation.SegAndTrack();
    case 'Existing'
        while(~goodLoad)
            fprintf('Select .mat data file...\n');
            [settings.matFile,settings.matFilePath,filterIndexMatFile] = uigetfile([settings.matFilePath '*.mat'],...
                ['Open Data (' CONSTANTS.datasetName ')']);
            
            if (filterIndexMatFile==0)
                return
            else
                fprintf('Opening file...');
                try
                    %clear out globals so they can rewriten
                    if(ishandle(Figures.cells.handle))
                        close Figures.cells.handle
                    end
                catch exception
                end
                
                rootImageFolder = CONSTANTS.rootImageFolder;
                imageSignificantDigits = CONSTANTS.imageSignificantDigits;
				
                try
                    load([settings.matFilePath settings.matFile]);
                    fprintf('\nFile open.\n\n');
                catch exception
                    fprintf('%s\n',exception.message);
                end
            end
            
            CONSTANTS.rootImageFolder = rootImageFolder;
            CONSTANTS.imageSignificantDigits = imageSignificantDigits;
            CONSTANTS.matFullFile = [settings.matFilePath settings.matFile];
            Load.InitializeConstants();
            
            if(exist('objHulls','var'))
                fprintf('Converting File...');
                Tracker.ConvertTrackingData(objHulls,gConnect);
                fprintf('\nFile Converted.\n');
                CONSTANTS.datasetName = strtok(settings.matFile,' ');
                Helper.SaveLEVerState([settings.matFilePath CONSTANTS.datasetName '_LEVer']);
                fprintf('New file saved as:\n%s_LEVer.mat',CONSTANTS.datasetName);
                goodLoad = 1;
            elseif(exist('CellHulls','var'))
                errors = mexIntegrityCheck();
                if ( ~isempty(errors) )
                    warndlg('There were database inconsistencies.  LEVer might not behave properly!');
                    Dev.PrintIntegrityErrors(errors);
                end
                goodLoad = 1;
            else
                errordlg('Data either did not load properly or is not the right format for LEVer.');
                goodLoad = 0;
            end
        end
        
        %save out settings
        save('LEVerSettings.mat','settings');
        
        Figures.time = 1;
        
        Error.LogAction(['Opened file ' settings.matFile]);
        
        errOpen = 0;
    otherwise
        return
end

opened = 1;

if(errOpen)
    opened = 0;
    return
end

bUpdated = Load.FixOldFileVersions(softwareVersion);
if ( bUpdated )
    Load.UpdateFileVersionString(softwareVersion);
    if( exist('objHulls','var') && strcmpi(answer,'Existing') )
        Helper.SaveLEVerState([settings.matFilePath CONSTANTS.datasetName '_LEVer']);
    else
        Helper.SaveLEVerState([settings.matFilePath settings.matFile]);
    end
end

% Initialized cached costs here if necessary (placed after fix old file versions for compatibility)
Load.InitializeCachedCosts(0);

if (~strcmp(imageDataset,CONSTANTS.datasetName))
    warndlg({'Image file name does not match .mat dataset name' '' 'LEVer may display cells incorectly!'},'Name mismatch','modal');
end

end
