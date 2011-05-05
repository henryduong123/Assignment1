%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     This file is part of LEVer.exe
%     (C) 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function SaveDataAs()
%Save the current state to a user defined dir


global CONSTANTS Figures

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
    SaveLEVerState(CONSTANTS.matFullFile);
else
    return
end


save('LEVerSettings.mat','settings');

%no longer "dirty"
set(Figures.tree.menuHandles.saveMenu,'Enable','off');
set(Figures.cells.menuHandles.saveMenu,'Enable','off');

LogAction(['Saved As: ' settings.matFile]);
end
