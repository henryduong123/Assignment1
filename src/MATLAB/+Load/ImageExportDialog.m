function jsonPath = ImageExportDialog(initialPath,promptTitle)
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
    
    [~,chkName,chkExt] = fileparts(fileName);
    if ( filterIndex == length(filterSpecs) && strcmpi(chkExt,'.json') )
        jsonPath = fullfile(rootDir,fileName);
        return;
    end
    
    [bNeedsExport,bWriteable,renameStruct] = Load.CheckExportImages(rootDir,fileName);
    if ( ~bNeedsExport )
        jsonList = dir(fullfile(rootDir,[chkName '*.json']));
        jsonPath = fullfile(rootDir,jsonList(1).name);
        return;
    end
    
    exportDir = Load.ExportLocationDialog(rootDir, bWriteable);
    if ( isempty(exportDir) )
        return;
    end
    
    if ( isempty(renameStruct) )
        jsonPath = Load.ExportImages(exportDir, rootDir,fileName);
    else
        jsonPath = Load.RenameImages(exportDir, rootDir, renameStruct);
    end
end
