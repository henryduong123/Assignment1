function jsonPath = ImageExportDialog(rootDir,filename)
    [bNeedsExport,bWriteable,renameStruct] = Load.CheckExportImages(rootDir,filename);
    if ( ~bNeedsExport )
        [~,chkName] = fileparts(filename);
        jsonList = dir(fullfile(rootDir,[chkName '*.json']));
        jsonPath = fullfile(rootDir,jsonList(1).name);
        return;
    end
    
    exportDir = Load.ExportLocationDialog(rootDir, bWriteable);
    if ( isempty(exportDir) )
        return;
    end
    
    if ( isempty(renameStruct) )
        jsonPath = Load.ExportImages(exportDir, rootDir,filename);
    else
        jsonPath = Load.RenameImages(exportDir, rootDir, renameStruct);
    end
end
