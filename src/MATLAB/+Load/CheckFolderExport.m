function [subPaths,needsExport,renamable] = CheckFolderExport(rootDir)
    [subPaths,needsExport,renamable] = recursiveCheckExport(rootDir,'');
end

function [subPaths,needsExport,renamable] = recursiveCheckExport(rootDir,subDir)
    subPaths = {};
    needsExport = false(0);
    renamable = false(0);
    
    dirList = dir(fullfile(rootDir,subDir));
    
    bInvalidName = arrayfun(@(x)(strncmpi(x.name,'.',1) || strncmpi(x.name,'..',2)), dirList);
    bValidDir = ~bInvalidName & (vertcat(dirList.isdir) > 0);
    bValidFile = ~bInvalidName & (vertcat(dirList.isdir) == 0);
    
    fileList = dirList(bValidFile);
    pathList = dirList(bValidDir);
    
    filenames = {fileList.name}.';
    
    %% Get a list of valid JSON files
    jsonMatch = regexpi(filenames, '(\.json$)','once');
    bJSON = cellfun(@(x)(~isempty(x)),jsonMatch);
    
    jsonNames = filenames(bJSON);
    if ( ~isempty(jsonNames) )
        bValid = cellfun(@(x)(~isempty(MicroscopeData.ReadMetadataFile(fullfile(rootDir,subDir,x)))),jsonNames);
        
        % Remove files that have the same prefix (datasetName) as .json from the list
        datasetNames = cellfun(@(x)(x(1:end-5)),jsonNames(bValid),'UniformOutput',false);
        matchDatasets = cellfun(@(x)(strncmp(x,filenames.',length(x))),datasetNames,'UniformOutput',false);
        bMatched = any(vertcat(matchDatasets{:}),1);
        filenames = filenames(~bMatched);
        
        subPaths = cellfun(@(x)(fullfile(subDir,x)),jsonNames(bValid),'UniformOutput',false);
        needsExport = false(nnz(bValid),1);
        renamable = false(nnz(bValid),1);
    end
    
    %% Handle folders of TIFs that don't require export or are renamable stacks
    tifMatch = regexpi(filenames, '(\.tif$)|(\.tiff$)','once');
    bTIF = cellfun(@(x)(~isempty(x)),tifMatch);
    
    tifNames = filenames(bTIF);
    if ( ~isempty(tifNames) )
        % If these appear to be renameable tifs don't bother with subdirectories
        [bNeedsExport,bWriteable,renameStruct] = Load.CheckExportImages(fullfile(rootDir,subDir),tifNames{1});
        if ( ~isempty(renameStruct) )
            subPaths = {fullfile(subDir,tifNames{1})};
            needsExport = bNeedsExport;
            renamable = bWriteable;
            
            return;
        end
    end
    
    %% Check any other files to see if they are supported and need export
    if ( ~isempty(filenames) )
        bCanExport = MicroscopeData.Original.CanExportFormat(filenames);
        exportNames = filenames(bCanExport);

        subPaths = [subPaths; cellfun(@(x)(fullfile(subDir,x)),exportNames,'UniformOutput',false)];
        needsExport = [needsExport; true(length(exportNames),1)];
        renamable = [renamable; false(length(exportNames),1)];
    end
    
    %% Deal with further subdirectories
    for i=1:length(pathList)
        nextSubDir = fullfile(subDir,pathList(i).name);
        [newPaths,chkExport,chkRename] = recursiveCheckExport(rootDir,nextSubDir);
        
        subPaths = [subPaths; newPaths];
        needsExport = [needsExport; chkExport];
        renamable = [renamable; chkRename];
    end
end
