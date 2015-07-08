function settings = ReadSettings()
    settingsPath = 'LEVerSettings.mat';
    if ( isdeployed() )
        appDir = getAppDir();
        settingsPath = fullfile(appDir,'LEVerSettings.mat');
    end
    
    settings = struct('settingsPath',{settingsPath}, 'imagePath',{''}, 'matFilePath',{''}, 'matFile',{'*.mat'});
    
    if ( exist(settingsPath, 'file') )
        load(settingsPath);
    end
    
    if ( ~isfield(settings,'matFilePath') )
        settings.matFilePath = '';
    end
    
    settings.settingsPath = settingsPath;
    Load.SaveSettings(settings);
end

function appDir = getAppDir()
    appDir = getenv('APPDATA');
    if ( isempty(appDir) )
        error('Unable to find application data directory');
    end
    
    appDir = fullfile(appDir,'LEVER');
    if ( ~exist(appDir, 'dir') )
        mkdir(appDir);
    end
end
