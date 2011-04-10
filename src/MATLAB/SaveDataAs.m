function SaveDataAs()
%Save the current state to a user defined dir

%--Eric Wait

global CellFamilies CellTracks HashedCells CONSTANTS Costs CellHulls Figures

if (exist('LEVerSettings.mat','file')~=0)
        load('LEVerSettings.mat');
else
    settings.matFilePath = '.\';
end

goodSave = 1;

while(goodSave)
    time = clock;
    fprintf('Choose a folder to save current data...\n');
    if(strcmp(settings.matFilePath,'.\'))
        [settings.matFile,settings.matFilePath,FilterIndex] = uiputfile('.mat','Save edits',...
        [CONSTANTS.datasetName '_LEVer.mat']);
    else
    [settings.matFile,settings.matFilePath,FilterIndex] = uiputfile('.mat','Save edits',...
        [CONSTANTS.datasetName ' edits ' num2str(time(1)) '-' num2str(time(2),'%02d') '-' num2str(time(3),'%02d') '_LEVer.mat']);
    end
    if (FilterIndex~=0)
        save([settings.matFilePath settings.matFile],...
            'CellFamilies','CellTracks','HashedCells','CONSTANTS','Costs','CellHulls');
        goodSave = 0;
    end
end

save('LEVerSettings.mat','settings');

%no longer "dirty"
set(Figures.tree.menuHandles.saveMenu,'Enable','off');
set(Figures.cells.menuHandles.saveMenu,'Enable','off');

LogAction(['Saved As: ' settings.matFile]);
end
