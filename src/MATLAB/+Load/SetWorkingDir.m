function SetWorkingDir()
    userDir = getenv('USERPROFILE');
    if ( isempty(userDir) )
        return;
    end
    
    docsDir = fullfile(userDir,'Documents');
    if ( ~exist(docsDir,'dir') )
        cd(userDir);
        return;
    end
    
    leverDir = fullfile(docsDir,'LEVER');
    if ( ~exist(leverDir) )
        mkdir(leverDir);
    end
    
    cd(leverDir);
end
