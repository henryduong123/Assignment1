function bOpened = ImageFileDialog()
global CONSTANTS

load('LEVerSettings.mat');

if ~isfield(settings,'imagePathFl')
    settings.imagePathFl = settings.imagePath;
end

%find the first image
imageFilter = [settings.imagePath '*.TIF'];

bOpened = 0;

while ( ~bOpened )  
	dataSetString = '';
    if ( isfield(CONSTANTS,'datasetName') )
        dataSetString = CONSTANTS.datasetName;
    end
    
    [settings.imageFile,settings.imagePath,filterIndexImage] = uigetfile(imageFilter,['Open First Image in Dataset (' dataSetString '): ' ]);
    if (filterIndexImage==0)
        return
    end
    
    [sigDigits imageDataset] = Helper.ParseImageName(settings.imageFile, 0);
    
    if ~isfield(CONSTANTS,'datasetName')
        Load.AddConstant('datasetName', imageDataset, 1);
    end
    if (strcmp(imageDataset,[CONSTANTS.datasetName '_']))
        Load.AddConstant('datasetName', [CONSTANTS.datasetName '_'], 1);
        bOpened = 1;
    elseif (~strcmp(imageDataset,CONSTANTS.datasetName))        
        answer = questdlg('Image does not match dataset would you like to choose another?','Image Selection','Yes','No','Close LEVer','Yes');
        switch answer
            case 'Yes'
                continue;
            case 'No'
                Load.AddConstant('imageNamePattern', '', 1);
                bOpened = 1;
            case 'Close LEVer'
                return
            otherwise
                continue;
        end
    end
    
    Load.AddConstant('rootImageFolder', settings.imagePath, 1);
    Load.AddConstant('imageSignificantDigits', sigDigits, 1);
    Load.AddConstant('matFullFile', [settings.matFilePath settings.matFile], 1);
    if (exist('fluorDataset'))
        Load.AddConstant('rootFluorFolder', settings.imagePathFl, 1);
    else
        Load.AddConstant('rootFluorFolder', '.\', 1);
        Load.AddConstant('fluorNamePattern', '.', 1);
    end
    
    bOpened = 1;
end

save('LEVerSettings.mat','settings');
end