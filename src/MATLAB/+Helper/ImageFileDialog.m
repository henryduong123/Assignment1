function bOpened = ImageFileDialog()
settings = Load.ReadSettings();

bOpened = 0;

while ( ~bOpened )
    [imageData, settings.imagePath] = MicroscopeData.ReadMetadata(settings.imagePath, true);
    if ( isempty(imageData) )
        return;
    end
    
    if ( ~isempty(Metadata.GetDatasetName()) && ~strcmp(Metadata.GetDatasetName(),imageData.DatasetName) )
        answer = questdlg('Image does not match dataset would you like to choose another?','Image Selection','Yes','No','Close LEVer','Yes');
        switch answer
            case 'Yes'
                continue;
            case 'No'
                bOpened = 1;
            case 'Close LEVer'
                return
            otherwise
                continue;
        end
    end
    
    Metadata.SetMetadata(imageData);
    
    Load.AddConstant('rootImageFolder', settings.imagePath, 1);
    Load.AddConstant('matFullFile', [settings.matFilePath settings.matFile], 1);
    
    bOpened = 1;
end

Load.SaveSettings(settings);
end
