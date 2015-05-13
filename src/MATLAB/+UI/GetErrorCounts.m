% there are 2*nHulls-1 total segmentation and tracking results
function [nSegmentationEdits, nTrackEdits, nMissingHulls, nHulls] = GetErrorCounts()

global CellFamilies CellTracks CellHulls Figures GraphEdits
% CountEdits
currentTree=Figures.tree.familyID;

[famHulls nMissingHulls] = Families.GetAllHulls(currentTree);
hx = GraphEdits(famHulls,famHulls);

nTrackEdits = nnz(any(abs(hx)==1,2));
nSegmentationEdits = nnz([CellHulls(famHulls).userEdited]~=0);
nHulls = length(famHulls);

end