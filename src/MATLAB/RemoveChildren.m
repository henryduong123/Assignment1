function RemoveChildren(trackID)
% RemoveChildren(trackID) removes the children of the given track and moves
% them to thier own trees.  Those new trees are attempted to be added to
% other trees. eg ProcessNewborns

%--Eric Wait

global CellTracks

familyIDs = [];
while ~isempty(CellTracks(trackID).childrenTracks)
    familyIDs = [familyIDs RemoveFromTree(CellTracks(CellTracks(trackID).childrenTracks(1)).startTime,CellTracks(trackID).childrenTracks(1),'no')];
end

CellTracks(trackID).childrenTracks = [];
%run processNewborns on them
ProcessNewborns(familyIDs);
end
