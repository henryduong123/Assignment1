function LinkTreeFolders(dataRootPath, pushSubdir)
    flist = dir(fullfile(dataRootPath,'*_LEVer.mat'));
    
    if ( ~exist('pushSubdir','var') )
        pushSubdir = 'Pushed';
    end
    
    for i=1:length(flist)
        if ( (flist(i).isdir) )
            continue
        end
        
        [fpath,filename,fext] = fileparts(flist(i).name);
        pushedFilename = [filename '.mat'];
        pushedPath = fullfile(dataRootPath,fpath,pushSubdir);
        
        if ( ~exist(pushedPath,'dir') )
            mkdir(pushedPath);
        end
        
        if ( exist(fullfile(pushedPath,pushedFilename), 'file') )
            continue;
        end
        
        clear global;
        load(fullfile(dataRootPath,flist(i).name));
        CONSTANTS.matFullFile = fullfile(pushedPath,pushedFilename);
        Helper.SaveLEVerState(CONSTANTS.matFullFile);
        
        try
            [iters totalTime] = Families.LinkFirstFrameTrees();
            Error.LogAction('Completed Tree Inference', [iters totalTime],[]);
            
            Segmentation.ResegRetrackLink();
        catch excp
            if ( exist(fullfile(pushedPath,pushedFilename), 'file') )
                delete(fullfile(pushedPath,pushedFilename));
            end
            
            errlog = fopen([CONSTANTS.datasetName '_push_error.log'], 'w');
            errStatus = Error.PrintException(excp);
            fprintf(errlog, '%s', errStatus);
            fclose(errlog);
            
            UI.Progressbar(1);
            continue;
        end
        Helper.SaveLEVerState(CONSTANTS.matFullFile);
    end
end
