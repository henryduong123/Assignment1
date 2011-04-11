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
if(isfield(Figures,'tree') && isfield(Figures.tree,'handle'))
    set(Figures.tree.handle,'Pointer','watch');
    set(Figures.cells.handle,'Pointer','watch');
end

save([settings.matFilePath CONSTANTS.datasetName '_LEVer_edits.mat'],...
    'CellFamilies','CellHulls','CellTracks','HashedCells','Costs','CONSTANTS');

%no longer "dirty"
if(isfield(Figures,'tree') && isfield(Figures.tree,'menuHandles') && isfield(Figures.tree.menuHandles,'saveMenu'))
    set(Figures.tree.menuHandles.saveMenu,'Enable','off');
    set(Figures.cells.menuHandles.saveMenu,'Enable','off');
end

LogAction('Saved');

%let the user know that the drawing is done
if(isfield(Figures,'tree') && isfield(Figures.tree,'handle'))
    set(Figures.tree.handle,'Pointer','arrow');
    set(Figures.cells.handle,'Pointer','arrow');
end
end
