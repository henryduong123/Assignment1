function BuildInstaller()
    compStruct = Dev.SetupCPPCompiler('vs2015');
    
    installDir = fullfile('..','..','installer');
    
    %% Load LEVER version info
    verInfo = Dev.VersionInfo();
    newVersion = [num2str(verInfo.majorVersion) '.' num2str(verInfo.minorVersion,'%2.1f')];
    
    %% Copy installer dependencies into the correct directory
    vcredistPath = fullfile(compStruct.toolroot,'..','..','VC','redist','1033',['vcredist_' compStruct.buildplatform '.exe']);
    system(['copy "' vcredistPath '" "' fullfile(installDir,'dependencies') '"']);
    
    mcrPath = mcrinstaller();
    [~,mcrFile,mcrExt] = fileparts(mcrPath);
    system(['copy "' mcrPath '" "' fullfile(installDir,'dependencies') '"']);
    
    %% Set environment variables installer needs
    setenv('LEVER_VER',newVersion);
    setenv('MCR_FILE',[mcrFile mcrExt]);
    
    %% Run installer build tasks
    result = system(['"' fullfile(compStruct.toolroot,'..','IDE','devenv.com') '"' ' /build "Release|' compStruct.buildplatform '" "' fullfile(installDir,'LEVER Install.sln') '"']);
    
    if ( result ~= 0 )
        error([fullfile(installDir,'LEVER Install.sln') ': Installer build failed.']);
    end
end
