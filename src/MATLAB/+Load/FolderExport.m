function exportRoot = FolderExport(rootDir)
    exportRoot = rootDir;
    
    [subPaths,needsExport,renamable] = Load.CheckFolderExport(rootDir);
    if ( isempty(subPaths) )
        return;
    end
    
    bExport = any(needsExport);
    if ( ~bExport )
        return;
    end
    
    % Allow an inplace update if all exports are renamable
    exportRenames = renamable(needsExport);
    exportPaths = subPaths(needsExport);
    
    bInplace = all(exportRenames);
    exportRoot = Load.ExportLocationDialog(rootDir, bInplace);
    if ( isempty(exportRoot) )
        return;
    end
    
    %% Copy all entries that don't need an export if we aren't doing inplace
    copyPaths = {};
    if ( ~strcmp(exportRoot,rootDir) )
        copyPaths = subPaths(~needsExport);
    end
    
    %% Copy all valid lever data to export directory
    for i=1:length(copyPaths)
        [subDir,filename] = fileparts(exportPaths{i});
        
        exportDir = fullfile(exportRoot,subDir);
        importDir = fullfile(rootDir,subDir);
        if ( ~exist(exportDir,'dir') )
            mkdir(exportDir);
        end
        
        copyfile(fullfile(importDir,[filename '*']),exportDir);
    end
    
    %% Export or rename/copy
    for i=1:length(exportPaths)
        [subDir,filename,fext] = fileparts(exportPaths{i});
        
        inputName = [filename fext];
        exportDir = fullfile(exportRoot,subDir);
        importDir = fullfile(rootDir,subDir);
        
        if ( ~exportRenames(i) )
            Load.ExportImages(exportDir, importDir,inputName);
        else
            renameStruct = Load.BuildRenameStruct(inputName);
            Load.RenameImages(exportDir, importDir,renameStruct,false);
        end
    end
end
