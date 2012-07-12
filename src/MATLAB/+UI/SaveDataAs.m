% SaveDataAs.m - Save the current state to a user defined dir

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     Copyright 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%     This file is part of LEVer - the tool for stem cell lineaging. See
%     https://pantherfile.uwm.edu/cohena/www/LEVer.html for details
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

function SaveDataAs()

global CONSTANTS

if (exist('LEVerSettings.mat','file')~=0)
        load('LEVerSettings.mat');
else
    settings.matFilePath = '.\';
end

time = clock;
fprintf('Choose a folder to save current data...\n');
if(strcmp(settings.matFilePath,'.\'))
    [settings.matFile,settings.matFilePath,FilterIndex] = uiputfile('.mat','Save edits',...
        [CONSTANTS.datasetName '_LEVer.mat']);
else
    [settings.matFile,settings.matFilePath,FilterIndex] = uiputfile('.mat','Save edits',...
        fullfile(settings.matFilePath, [CONSTANTS.datasetName ' edits ' num2str(time(1)) '-' num2str(time(2),'%02d') '-' num2str(time(3),'%02d') '_LEVer.mat']));
end
if (FilterIndex~=0)
    CONSTANTS.matFullFile = [settings.matFilePath settings.matFile];
    Helper.SaveLEVerState(CONSTANTS.matFullFile);
else
    return
end

save('LEVerSettings.mat','settings');

Error.LogAction(['Saved As: ' settings.matFile]);
end
