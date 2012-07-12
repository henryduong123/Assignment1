function ImageFileDialog()
global CONSTANTS

oldCONSTANTS = CONSTANTS;

load('LEVerSettings.mat');

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
    CONSTANTS.datasetName = imageDataset;
    CONSTANTS.imageSignificantDigits = sigDigits;
    CONSTANTS.matFullFile = [settings.matFilePath settings.matFile];
    fileName = Helper.GetFullImagePath(1);
    
    tryidx = tryidx + 1;
end

save('LEVerSettings.mat','settings');
end