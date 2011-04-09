function familyIDs = StraightenTrack(trackID)
% StraightenTrack(trackID) will drop all right children while traversing
% left.  Usefull for cells that should not have mitosis events such as dead
% cells.

%--Eric Wait

global CellTracks
familyIDs = [];
if(~isempty(CellTracks(trackID).childrenTracks))
    familyIDs = StraightenTrack(CellTracks(trackID).childrenTracks(1));
    for i=2:length(CellTracks(trackID).childrenTracks)
        familyIDs = [familyIDs RemoveFromTree(CellTracks(CellTracks(trackID).childrenTracks(i)).startTime,...
            CellTracks(trackID).childrenTracks(i),'yes')];
    end
end
end