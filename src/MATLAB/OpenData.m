%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     This file is part of LEVer.exe
%     (C) 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function opened = OpenData(versionString)
%Opens the data file either from a previous state of LEVer or from tracking
%results.  If the latter, the data will be converted to LEVer's data scheme
%and save out to a new file.


global Figures Colors CONSTANTS CellFamilies CellHulls HashedCells Costs GraphEdits CellTracks ConnectedDist CellPhenotypes SegmentationEdits

if(isempty(Figures))
    fprintf('LEVer ver %s\n***DO NOT DISTRIBUTE***\n\n', versionString);
end

if(exist('ColorScheme.mat','file'))
    load 'ColorScheme.mat'
    Colors = colors;
else
    %the lowercase var is saved out where the capital var the one used
    colors = CreateColors();
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
                SaveData(0);
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
SegmentationEdits.maxEditedFrame = length(HashedCells);
SegmentationEdits.editTime = [];

oldCONSTANTS = CONSTANTS;

%find the first image
imageFilter = [settings.imagePath '*.TIF'];
while (filterIndexImage==0)
    fprintf('\nSelect first .TIF image...\n\n');
    [settings.imageFile,settings.imagePath,filterIndexImage] = uigetfile(imageFilter,'Open First Image in dataset: ');
    if (filterIndexImage==0)
        CONSTANTS = oldCONSTANTS;
        return
    end
end

index = strfind(settings.imageFile,'_t');
if (~isempty(index) && filterIndexImage~=0)
    CONSTANTS.rootImageFolder = settings.imagePath;
    imageDataset = settings.imageFile(1:(index(length(index))-1));
    CONSTANTS.imageDatasetName = imageDataset;
    CONSTANTS.datasetName = imageDataset;
    index2 = strfind(settings.imageFile,'.');
    CONSTANTS.imageSignificantDigits = index2 - index - 2;
    fileName=[CONSTANTS.rootImageFolder imageDataset '_t' SignificantDigits(1) '.TIF'];
end

while (isempty(index) || ~exist(fileName,'file'))
    fprintf('Image file name not in correct format:%s_t%s.TIF\nPlease choose another...\n',CONSTANTS.datasetName,frameT);
    [settings.imageFile,settings.imagePath,filterIndexImage] = uigetfile(settings.imagePath,'Open First Image');
    if(filterIndexImage==0)
        CONSTANTS = oldCONSTANTS;
        return
    end
    index = strfind(imageFile,'t');
    CONSTANTS.rootImageFolder = [settings.imagePath '\'];
    imageDataset = imageFile(1:(index(length(index))-2));
    fileName=[CONSTANTS.rootImageFolder imageDataSet '_t' SignificantDigits(t) '.TIF'];
end

answer = questdlg('Run Segmentation and Tracking or Use Existing Data?','Data Source','Segment & Track','Existing','Existing');
switch answer
    case 'Segment & Track'
        save('LEVerSettings.mat','settings');
        InitializeConstants();
        UpdateFileVersionString(versionString);
        opened = SegAndTrack();
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
                catch
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
            InitializeConstants();
            
            if(exist('objHulls','var'))
                fprintf('Converting File...');
                ConvertTrackingData(objHulls,gConnect);
                fprintf('\nFile Converted.\n');
                CONSTANTS.datasetName = strtok(settings.matFile,' ');
                SaveLEVerState([settings.matFilePath CONSTANTS.datasetName '_LEVer']);
                fprintf('New file saved as:\n%s_LEVer.mat',CONSTANTS.datasetName);
                goodLoad = 1;
            elseif(exist('CellHulls','var'))
                try
                    TestDataIntegrity(1);
                catch errorMessage
                    warndlg('There were database inconsistencies.  LEVer might not behave properly!');
                    Progressbar(1);
                    fprintf('%s\n',errorMessage.message);
                    LogAction(errorMessage.message);
                end
                GraphEdits = sparse([], [], [], size(Costs,1), size(Costs,2), round(0.1*size(Costs,2)));
                goodLoad = 1;
            else
                errordlg('Data either did not load properly or is not the right format for LEVer.');
                goodLoad = 0;
            end
        end
        
        %save out settings
        save('LEVerSettings.mat','settings');
        
        Figures.time = 1;
        
        LogAction(['Opened file ' settings.matFile]);
        
        opened = 1;
    otherwise
        return
end

if(~opened),return,end

StraightenFamilies();
ProcessNewborns(1:length(CellFamilies),length(HashedCells));

bUpdated = FixOldFileVersions(versionString);
if ( bUpdated )
    UpdateFileVersionString(versionString);
    if( exist('objHulls','var') && strcmpi(answer,'Existing') )
        SaveLEVerState([settings.matFilePath CONSTANTS.datasetName '_LEVer']);
    else
        SaveLEVerState([settings.matFilePath settings.matFile]);
    end
end

if (~strcmp(imageDataset,CONSTANTS.datasetName))
    warndlg({'Image file name does not match .mat dataset name' '' 'LEVer may display cells incorectly!'},'Name mismatch','modal');
end

end
