function newPreserveTracks = LinkupEdges(edges, preserveTracks)
    global CellTracks
    
    newPreserveTracks = [];
    for i=1:size(edges,1)
        parentTrackID = Hulls.GetTrackID(edges(i,1));
        childTrackID = Hulls.GetTrackID(edges(i,2));
        
        childTime = CellTracks(childTrackID).startTime;
        
        parentHull = Tracks.GetHullID(childTime, parentTrackID);
        if ( parentHull > 0 )
            Families.AddToTree(childTrackID, parentTrackID);
            newPreserveTracks = [newPreserveTracks CellTracks(parentTrackID).childrenTracks];
        else
            Tracks.ChangeLabel(childTrackID, parentTrackID, childTime);
            newPreserveTracks = [newPreserveTracks parentTrackID];
        end
    end
    
    newPreserveTracks = setdiff(newPreserveTracks, preserveTracks);
end