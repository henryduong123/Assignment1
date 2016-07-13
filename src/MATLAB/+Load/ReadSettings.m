
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
