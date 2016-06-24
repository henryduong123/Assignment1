function jsonPath = ImageLoadDialog(initialPath,promptTitle)
    filterSpecs = {'*.json','LEVER Metadata (*.json)';
                    '*.lif;*.lei','Leica LAS (*.lif,*.lei)';
                    '*.czi;*.lsm;*.zvi','Zeiss (*.czi,*.lsm,*.zvi)';
                    '*.tif;*.tiff','TIFF Images (*.tif,*.tiff)';
                    '*.*','All Files (*.*)'};
	
	jsonPath = '';
	
    [fileName,rootDir,filterIndex] = uigetfile(filterSpecs,promptTitle,initialPath);
    if (filterIndex==0)
        return
    end
    
    if ( filterIndex == 1 )
        jsonPath = fullfile(rootDir,fileName);
        return
    end
    
    [~,~,chkExt] = fileparts(fileName);
    if ( filterIndex == length(filterSpecs) && strcmpi(chkExt,'.json') )
        jsonPath = fullfile(rootDir,fileName);
        return;
    end
    
	jsonPath = Load.ImageExportDialog(rootDir,fileName);
end
