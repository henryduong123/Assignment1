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
