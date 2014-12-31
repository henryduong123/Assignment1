% there are 2*nHulls-1 total segmentation and tracking results
function [nSegmentationEdits, nTrackEdits, nMissingHulls, nHulls] = GetErrorCounts()

global CellFamilies CellTracks CellHulls Figures GraphEdits
% CountEdits
currentTree=Figures.tree.familyID;

nHulls = 0;
nMissingHulls=0;
nSegmentationEdits=0;
nTrackEdits=0;

nTracks=length(CellFamilies(currentTree).tracks);
for tid=1:nTracks
    ID = CellFamilies(currentTree).tracks(tid);
    
    hulls =(CellTracks(ID).hulls);
    nHulls=nHulls+length(find(hulls~=0));
    
    nMissingHulls=nMissingHulls+length(find(hulls==0));
    hulls(hulls==0)=[];
    
    nTrackEdits=nTrackEdits+ nnz(any(GraphEdits(hulls,:),1));
    nSegmentationEdits=nSegmentationEdits+length(find([CellHulls(hulls).userEdited]~=0));
     
end