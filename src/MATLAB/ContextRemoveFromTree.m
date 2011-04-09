function ContextRemoveFromTree(time,trackID)
%context menu callback function
global CellTracks

oldFamilyID = CellTracks(trackID).familyID;

newFamilyID = RemoveFromTree(time, trackID);
History('Push');
LogAction(['Removed part or all of ' num2str(trackID) ' from tree'],oldFamilyID,newFamilyID);

DrawTree(oldFamilyID);
DrawCells();
end
