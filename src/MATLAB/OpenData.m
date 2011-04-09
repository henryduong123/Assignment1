function opened = OpenData()
%Opens the data file either from a previous state of LEVer or from tracking
%results.  If the latter, the data will be converted to LEVer's data scheme
%and save out to a new file.

global Figures Colors CONSTANTS CellFamilies CellHulls HashedCells Costs CellTracks
if(isempty(Figures))
    fprintf('LEVer ver 3.0\n***DO NOT DISTRIBUTE***\n\n');
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
matPath = [];
imageFile = [];
imagePath = [];
imageDataset = [];
goodLoad = 0;
opened = 0;

% .mat file handling
while(~goodLoad)
    fprintf('Select .mat data file...\n');
    [matFile,matPath,filterIndexMatFile] = uigetfile([settings.matFilePath '*.mat'],...
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
        CONSTANTS = [];
        try
            load([matPath matFile]);
            fprintf('\nFile open.\n\n');
        catch exception
            %DEBUG -- Uncomment
            %disp(exception);
        end
    end
    
    if(exist('objHulls','var'))
        fprintf('Converting File...');
        ConvertTrackingData(objHulls,gConnect);
        fprintf('\nFile Converted.\n');
        CONSTANTS.datasetName = strtok(matFile,' ');
        save([matPath CONSTANTS.datasetName '_LEVer'],...
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

%find the first image
imageFilter = [settings.imagePath '*' CONSTANTS.datasetName '*.TIF'];
while (filterIndexImage==0)
    fprintf('\nSelect first .TIF image...\n\n');
    [imageFile,imagePath,filterIndexImage] = uigetfile(imageFilter,['Open First Image in dataset: ' CONSTANTS.datasetName]);
    if (filterIndexImage==0)
        return
    end
end

opened = 1;

index = strfind(imageFile,'t');
if (~isempty(index) && filterIndexImage~=0)
    CONSTANTS.rootImageFolder = imagePath;
    imageDataset = imageFile(1:(index(length(index))-2));
    fileName=[CONSTANTS.rootImageFolder imageDataset '_t001.TIF'];
end

while (isempty(index) || ~exist(fileName,'file'))
    fprintf(['Image file name not in correct format: ' CONSTANTS.datasetName '_t001.TIF\nPlease choose another...\n']);
    [imageFile,imagePath,filterIndexImage] = uigetfile(settings.imagePath,'Open First Image');
    index = strfind(imageFile,'t');
    CONSTANTS.rootImageFolder = [imgPath '\'];
    imageDataset = imageFile(1:(index(length(index))-2));
    fileName=[CONSTANTS.rootImageFolder imageDataSet '_t' num2str(t,'%03d') '.TIF'];
end

%save out settings
settings.matFilePath = matPath;
settings.imageFile = imageFile;
settings.imagePath = [imagePath '\'];
save('LEVerSettings.mat','settings');

if (~strcmp(imageDataset,CONSTANTS.datasetName))
    warndlg({'Image file name does not match .mat dataset name' '' 'LEVer may display cells incorectly!'},'Name mismatch','modal');
end

if(~isempty(Figures) && ishandle(Figures.cells.handle))
    close(Figures.cells.handle);
end

Figures.time = 1;

LogAction(['Opened file ' matFile],[],[]);

end
