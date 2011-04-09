function SaveDataAs()
global CellFamilies CellTracks HashedCells CONSTANTS Costs CellHulls Figures

if (exist('LEVerSettings.mat','file')~=0)
        load('LEVerSettings.mat');
else
    settings.matPath = ['.\' CONSTANTS.datasetName '_LEVer.mat'];
end

goodSave = 1;

while(goodSave)
    time = clock;
    fprintf('Choose a folder to save current data...\n');
    [FileName,PathName,FilterIndex] = uiputfile('.mat','Save edits',...
        [CONSTANTS.datasetName ' edits ' num2str(time(1)) '-' num2str(time(2),'%02d') '-' num2str(time(3),'%02d') '_LEVer.mat']);
    if (FilterIndex~=0)
        save([PathName FileName],...
            'CellFamilies','CellTracks','HashedCells','CONSTANTS','Costs','CellHulls');
        goodSave = 0;
    end
end

settings.matPath = [FileName PathName];
save('LEVerSettings.mat','settings');

%no longer "dirty"
set(Figures.tree.menuHandles.saveMenu,'Enable','off');
set(Figures.cells.menuHandles.saveMenu,'Enable','off');

LogAction(['Saved As: ' FileName],[],[]);
end
