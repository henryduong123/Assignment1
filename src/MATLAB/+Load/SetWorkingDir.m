function SetWorkingDir()

appDir=getenv('APPDATA');
appDir=[appDir '\LEVER'];
if ~exist(appDir)
    mkdir(appDir);
end
cd(appDir);