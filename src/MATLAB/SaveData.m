function SaveData()
%This will save the current state back to the opened dataset

%--Eric Wait

global CellFamilies CellTracks HashedCells CONSTANTS Costs CellHulls Figures

if (exist('LEVerSettings.mat','file')~=0)
        load('LEVerSettings.mat');
else
    settings.matFilePath = '.\';
end

%let the user know that this might take a while
set(Figures.tree.handle,'Pointer','watch');
set(Figures.cells.handle,'Pointer','watch');

save([settings.matFilePath CONSTANTS.datasetName '_LEVer_edits.mat'],...
    'CellFamilies','CellHulls','CellTracks','HashedCells','Costs','CONSTANTS');

%no longer "dirty"
set(Figures.tree.menuHandles.saveMenu,'Enable','off');
set(Figures.cells.menuHandles.saveMenu,'Enable','off');

LogAction('Saved',[],[]);

%let the user know that the drawing is done
set(Figures.tree.handle,'Pointer','arrow');
set(Figures.cells.handle,'Pointer','arrow');
end
