
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
