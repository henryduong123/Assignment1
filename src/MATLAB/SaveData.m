function SaveData()
%This will save the current state back to the opened dataset
global CellFamilies CellTracks HashedCells CONSTANTS Costs CellHulls

if (exist('LEVerSettings.mat','file')~=0)
        load('LEVerSettings.mat');
else
    settings.matPath = ['.\' CONSTANTS.datasetName '_v3.mat'];
end

save(settings.matPath,...
    'CellFamilies','CellHulls','CellTracks','HashedCells','Costs','CONSTANTS');

%no longer "dirty"
set(Figures.tree.menuHandles.saveMenu,'Enable','off');
set(Figures.cells.menuHandles.saveMenu,'Enable','off');

LogAction('Saved',[],[]);
end
