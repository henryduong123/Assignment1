function bOpened = ImageFileDialog()
global CONSTANTS

oldCONSTANTS = CONSTANTS;

load('LEVerSettings.mat');

%find the first image
imageFilter = [settings.imagePath '*.TIF'];

bOpened = 0;

while ( ~bOpened )  
    [settings.imageFile,settings.imagePath,filterIndexImage] = uigetfile(imageFilter,'Open First Image in dataset: ');
    if (filterIndexImage==0)
        CONSTANTS = oldCONSTANTS;
        return
    end
    
    [sigDigits imageDataset] = Helper.ParseImageName(settings.imageFile);
    
    if (~isfield(CONSTANTS,'datasetName'))
        CONSTANTS.datasetName = imageDataset;
    elseif (~strcmp(imageDataset,CONSTANTS.datasetName))
        answer = questdlg('Image does not match dataset would you like to choose another?','Image Selection','Yes','No','Close LEVer','Yes');
        switch answer
            case 'Yes'
                continue;
            case 'No'
                CONSTANTS.imageNamePattern = '';
            case 'Close LEVer'
                return
            otherwise
                continue;
        end
    end
    
    CONSTANTS.rootImageFolder = settings.imagePath;
    CONSTANTS.imageSignificantDigits = sigDigits;
    CONSTANTS.matFullFile = [settings.matFilePath settings.matFile];
    
    bOpened = 1;
end

save('LEVerSettings.mat','settings');
end