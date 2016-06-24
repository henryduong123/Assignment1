function jsonPath = RenameImages(exportDir,inRoot, renameStruct, bCreateDatasetDir)
    if ( ~exist('bCreateDatasetDir','var') )
        bCreateDatasetDir = true;
    end

    fileOp = @(src,dst)(movefile(src,dst,'f'));
    if ( ~strcmp(exportDir,inRoot) )
        fileOp = @(src,dst)(copyfile(src,dst,'f'));
        
        if ( bCreateDatasetDir )
            exportDir = fullfile(exportDir,renameStruct.datasetName);
        end
    end
    % fileOp = @(src,dst)(fprintf('%s -> %s\n', src,dst));
    
    if ( ~exist(exportDir,'dir') )
        mkdir(exportDir);
    end
    
    flist = dir(fullfile(inRoot,renameStruct.dirBlob));
    nameList = {flist.name}.';
    
    loadTok = regexp(nameList, renameStruct.loadPattern, 'tokens','once');
    
    bValidParams = (renameStruct.paramOrder > 0);
    paramIdx = find(bValidParams);
    validOrder = paramIdx(renameStruct.paramOrder(bValidParams));
    
    bValidNames = cellfun(@(x)(length(x)==nnz(bValidParams)), loadTok);
    paramTok = vertcat(loadTok{bValidNames});
    
    paramVals = ones(size(paramTok,1),length(renameStruct.paramOrder));
    paramVals(:,validOrder) = cellfun(@(x)(str2double(x)), paramTok);
    
    paramMin = min(paramVals,[],1);
    paramOffset = 1 - paramMin;
    
    validNames = nameList(bValidNames);
    for i=1:length(validNames)
        paramCell = num2cell(paramVals(i,:)+paramOffset);
        outName = sprintf(renameStruct.outPattern,paramCell{:});
        
        fileOp(fullfile(inRoot,validNames{i}),fullfile(exportDir,outName));
    end
    
    imageData = MicroscopeData.MakeMetadataFromFolder(exportDir,renameStruct.datasetName);
    MicroscopeData.CreateMetadata(exportDir,imageData,true);
    
    jsonPath = fullfile(exportDir,[renameStruct.datasetName '.json']);
end
