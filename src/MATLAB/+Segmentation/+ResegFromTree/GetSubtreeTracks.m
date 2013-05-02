% childTracks = GetSubtreeTracks(rootTracks)
% 
% Returns a list of all tracks which are children of the tracks listed in
% rootTracks (Includes the rootTracks).

function childTracks = GetSubtreeTracks(rootTracks)
    global CellTracks
    
    childTracks = rootTracks;
    while ( any(~isempty([CellTracks(childTracks).childrenTracks])) )
        newTracks = setdiff([CellTracks(childTracks).childrenTracks], childTracks);
        if ( isempty(newTracks) )
            return;
        end
        
        childTracks = union(childTracks, newTracks);
    end
end