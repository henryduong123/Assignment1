
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

function exportLocation = ExportLocationDialog(rootDir,bInplace)
    exportLocation = '';
    
    % Offer to update the image names/json in place if possible.
    if ( bInplace )
        selAns = questdlg({'Selected images must be updated to conform to LEVER naming and metadata guidelines:',...
                'Image name format: <DatasetName>_c%02d_t%04d_z%04d.tif',...
                ' ',...
                'The images can be updated in place or exported to a new directory.'},...
                'Image Export Required', 'Update','Export','Update');

        if ( isempty(selAns) )
            return;
        end

        if ( strcmpi(selAns,'Update') )
            exportLocation = rootDir;
            return;
        end
    end
    
    while ( true )
        chkDir = uigetdir(rootDir, 'Image Export Directory');
        if ( ~chkDir )
            return;
        end
        
        if ( strcmp(chkDir,rootDir) )
            h = warndlg('Please select or create a different directory to export into.','Export Required');
            uiwait(h);
        else
            exportLocation = chkDir;
            return;
        end
    end
end
