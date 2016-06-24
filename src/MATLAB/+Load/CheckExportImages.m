% [bNeedsExport,bInplaceUpdate] = CheckExportImages(rootDir,fileName)
% 
% Check if these specified image file needs to be exported for LEVER use or
% or if only an inplace rename and json generation is required.

function [bNeedsExport,bWriteable,renameStruct] = CheckExportImages(rootDir,fileName)
    bNeedsExport = false;
    bWriteable = false;
    renameStruct = [];
    
    [~,chkName,chkExt] = fileparts(fileName);
    if ( any(strcmpi(chkExt,{'.tif','.tiff'})) )
        jsonList = dir(fullfile(rootDir,[chkName '*.json']));
        if ( ~isempty(jsonList) )
            return;
        end
        
        renameStruct = Load.BuildRenameStruct(fileName);
    end
    
    bWriteable = ~isempty(renameStruct) && checkWriteable(rootDir);
    bNeedsExport = true;
end

function bCanWrite = checkWriteable(rootDir)
    bCanWrite = false;
    
    fid = fopen(fullfile(rootDir,'testWriteFile'),'w');
    if ( fid < 0 )
        return;
    end
    fclose(fid);
    
    delete(fullfile(rootDir,'testWriteFile'));
    
    bCanWrite = true;
end