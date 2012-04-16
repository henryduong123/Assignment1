function LinkTreeFolders(dataRootPath)
    flist = dir(fullfile(dataRootPath,'*_LEVer.mat'));
    for i=1:length(flist)
        if ( (flist(i).isdir) )
            continue
        end
        
        [fpath,filename,fext] = fileparts(flist(i).name);
        pushedFilename = [filename '_pushed.mat'];
        
        if ( exist(fullfile(dataRootPath,fpath,pushedFilename), 'file') )
            continue;
        end
        
        clear global;
        load(fullfile(dataRootPath,flist(i).name));
        CONSTANTS.matFullFile = fullfile(dataRootPath,fpath,pushedFilename);
        SaveLEVerState(CONSTANTS.matFullFile);
        
        try
%             LinkFirstFrameTrees();
            LinkResegRetrack();
        catch excp
            if ( exist(fullfile(dataRootPath,fpath,pushedFilename), 'file') )
                delete(fullfile(dataRootPath,fpath,pushedFilename));
            end
            
            errlog = fopen([CONSTANTS.datasetName '_push_error.log'], 'w');
            PrintException(errlog,excp);
            fclose(errlog);
            
            Progressbar(1);
            continue;
        end
        SaveLEVerState(CONSTANTS.matFullFile);
    end
end