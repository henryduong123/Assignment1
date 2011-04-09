function opened = OpenData()
%Opens the data file either from a previous state of LEVer or from tracking
%results.  If the latter, the data will be converted to LEVer's data scheme
%and save out to a new file.

%--Eric Wait

global Figures Colors CONSTANTS CellFamilies CellHulls HashedCells Costs CellTracks
if(isempty(Figures))
    fprintf('LEVer ver 4.0\n***DO NOT DISTRIBUTE***\n\n');
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
    if (exist('LEVerSettings.mat','file')~=0)
        load('LEVerSettings.mat');
    else
        settings.imagePath = '.\';
        settings.matFilePath = '.\';
    end
end

filterIndexImage = 0;
matFile = [];
matFilePath = [];
imageFile = [];
imagePath = [];
imageDataset = [];
goodLoad = 0;
opened = 0;

if(~isempty(Figures))
    if(strcmp(get(Figures.cells.menuHandles.saveMenu,'Enable'),'on'))
        choice = questdlg('Save current edits before opening new data?','Closing','Yes','No','Cancel','Cancel');
        switch choice
            case 'Yes'
                SaveData();
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

oldCONSTANTS = CONSTANTS;
InitializeConstants();

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
frameT = '001';
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
    fprintf(['Image file name not in correct format: ' CONSTANTS.datasetName '_t' frameT '.TIF\nPlease choose another...\n']);
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
        SegAndTrack();
    case 'Existing'
        while(~goodLoad)
            fprintf('Select .mat data file...\n');
            [settings.matFile,settings.matFilePath,filterIndexMatFile] = uigetfile([settings.matFilePath '*.mat'],...
                'Open Data');
            
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
                CellFamilies = [];
                CellTracks = [];
                CellHulls = [];
                HashedCells = [];
                Costs = [];
				rootImageFolder = CONSTANTS.rootImageFolder;
                imageSignificantDigits = CONSTANTS.imageSignificantDigits;
				
                try
                    load([settings.matFilePath settings.matFile]);
                    fprintf('\nFile open.\n\n');
                catch exception
                    %DEBUG -- Uncomment
                    %disp(exception);
                end
            end
            
            CONSTANTS.rootImageFolder = rootImageFolder;
            CONSTANTS.imageSignificantDigits = imageSignificantDigits;
            InitializeConstants();
            
            if(exist('objHulls','var'))
                fprintf('Converting File...');
                ConvertTrackingData(objHulls,gConnect);
                fprintf('\nFile Converted.\n');
                CONSTANTS.datasetName = strtok(matFile,' ');
                save([settings.matFilePath CONSTANTS.datasetName '_LEVer'],...
                    'CellFamilies','CellHulls','CellTracks','HashedCells','Costs','CONSTANTS');
                fprintf(['New file saved as:\n' CONSTANTS.datasetName '_LEVer.mat']);
                goodLoad = 1;
            elseif(exist('CellHulls','var'))
                goodLoad = 1;
            else
                errordlg('Data either did not load properly or is not the right format for LEVer.');
                goodLoad = 0;
            end
        end
        
        %save out settings
        save('LEVerSettings.mat','settings');
        
        Figures.time = 1;
        
        LogAction(['Opened file ' matFile],[],[]);
    otherwise
        return
end

% Add imagePixels field to CellHulls structure (and resave in place)
if ( ~isfield(CellHulls, 'imagePixels') )
    fprintf('Adding Image Pixel Information...\n');
    AddImagePixelsField();
    fprintf('Image Information Added\n');
    save([settings.matFilePath settings.matFile],...
        'CellFamilies','CellHulls','CellTracks','HashedCells','Costs','CONSTANTS');
end

opened = 1;

if (~strcmp(imageDataset,CONSTANTS.datasetName))
    warndlg({'Image file name does not match .mat dataset name' '' 'LEVer may display cells incorectly!'},'Name mismatch','modal');
end

end
