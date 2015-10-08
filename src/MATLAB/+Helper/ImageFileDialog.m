function bOpened = ImageFileDialog()
global CONSTANTS

settings = Load.ReadSettings();

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
    
    [imageDataset namePattern] = Helper.ParseImageName(settings.imageFile);
    if ( isempty(imageDataset) )
        error('File name pattern is not supported: %s', settings.imageFile);
    end
    
    Load.AddConstant('imageNamePattern', namePattern, 1);
    if ( ~isfield(CONSTANTS,'datasetName') )
        Load.AddConstant('datasetName', imageDataset, 1);
    end
    
    if ( strcmp(imageDataset, [CONSTANTS.datasetName '_']) )
        Load.AddConstant('datasetName', [CONSTANTS.datasetName '_'], 1);
        bOpened = 1;
    elseif ( ~strcmp(imageDataset, CONSTANTS.datasetName) )
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
    Load.AddConstant('matFullFile', [settings.matFilePath settings.matFile], 1);
    
    [channelList, frameList] = Helper.GetImListInfo(settings.imagePath, namePattern);
    
    % Verify that channel and time are 1-based.
    remapChan = 1 - channelList(1);
    remapFrame = 1 - frameList(1);
    if ( remapChan ~= 0 || remapFrame ~= 0 )
        queryStr = sprintf('LEVER requires that image channel and frame numbers begin at 1.\nWould you like to automatically rename the images in the selected folder?');
        respStr = questdlg(queryStr,'Image Name Unsupported','Ok','Cancel','Ok');
        if ( strcmpi(respStr,'Cancel') )
            return;
        end
        
        for c=channelList(1):channelList(end)
            for t=frameList(1):frameList(end)
                oldName = Helper.GetImageName(c,t);
                tempName = ['tmp_' Helper.GetImageName(c+remapChan, t+remapFrame)];
                if ( ~exist(fullfile(settings.imagePath,oldName), 'file') )
                    continue;
                end
                
                movefile(fullfile(settings.imagePath,oldName), fullfile(settings.imagePath,tempName));
            end
        end
        
        for c=channelList(1):channelList(end)
            for t=frameList(1):frameList(end)
                tempName = ['tmp_' Helper.GetImageName(c+remapChan, t+remapFrame)];
                newName = Helper.GetImageName(c+remapChan, t+remapFrame);
                if ( ~exist(fullfile(settings.imagePath,tempName), 'file') )
                    continue;
                end
                
                movefile(fullfile(settings.imagePath,tempName), fullfile(settings.imagePath,newName));
            end
        end
        
        channelList = channelList + remapChan;
        frameList = frameList + remapFrame;
    end
    
    Load.AddConstant('numFrames', frameList(end), 1);
    Load.AddConstant('numChannels', channelList(end), 1);
    
    bOpened = 1;
end

Load.SaveSettings(settings);
end
