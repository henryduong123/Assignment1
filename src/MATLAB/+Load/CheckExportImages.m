% [bNeedsExport,bInplaceUpdate] = CheckExportImages(rootDir,fileName)
% 
% Check if these specified image file needs to be exported for LEVER use or
% or if only an inplace rename and json generation is required.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     Copyright 2016 Drexel University
%
%     This file is part of LEVer - the tool for stem cell lineaging. See
%     http://n2t.net/ark:/87918/d9rp4t for details
% 
%     LEVer is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
%     LEVer is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
% 
%     You should have received a copy of the GNU General Public License
%     along with LEVer in file "gnu gpl v3.txt".  If not, see 
%     <http://www.gnu.org/licenses/>.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


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