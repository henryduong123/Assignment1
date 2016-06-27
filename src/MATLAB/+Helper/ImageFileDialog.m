
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     Copyright 2011-2016 Andrew Cohen
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

function bOpened = ImageFileDialog()
settings = Load.ReadSettings();

bOpened = 0;

while ( ~bOpened )
    metadataPath = Load.ImageLoadDialog(settings.imagePath,['Open Dataset Metadata or Image (' Metadata.GetDatasetName() '): ']);
    if ( isempty(metadataPath) )
        return;
    end
    
    [imageData, settings.imagePath] = MicroscopeData.ReadMetadataFile(metadataPath);
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
