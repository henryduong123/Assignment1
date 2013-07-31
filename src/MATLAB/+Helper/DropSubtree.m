
function DropSubtree(trackID)
    global CellTracks
    
    if ( isempty(CellTracks(trackID).startTime) )
        error('Cannot drop subtree of an empty track!');
    end
    
    % Remove children if this is a length 1 track
    if ( ~isempty(CellTracks(trackID).childrenTracks) )
        Families.RemoveFromTreePrune(CellTracks(trackID).childrenTracks(1));
    end
    
    Families.RemoveFromTreePrune(trackID, CellTracks(trackID).startTime+1);
end