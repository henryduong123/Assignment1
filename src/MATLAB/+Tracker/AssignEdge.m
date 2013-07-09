% changedHulls = AssignEdge(trackHull, assignHull)
% 
% Assign the edge from trackHull to assignHull, this changes the track
% assignment for assignHull such that it will be on the same track as
% trackHull.

function changedHulls = AssignEdge(trackHull, assignHull)
    global CellHulls CellTracks CellFamilies
    
    changedHulls = [];
    
     % Get track to which we will assign hull from trackHull
    track = Hulls.GetTrackID(trackHull);
    
    assignTime = CellHulls(assignHull).time;
    trackTime = CellHulls(trackHull).time;
    
    oldTrackHull = Tracks.GetHullID(assignTime, track);
    oldAssignTrack = Hulls.GetTrackID(assignHull);
    
    dir = sign(assignTime - trackTime);
    
    % Hull - track assignment is unchanged
    if ( oldTrackHull == assignHull )
        return;
    end
    
    [bLocked bCanChange] = Tracks.CheckLockedChangeLabel(oldAssignTrack, track, assignTime);
    if ( ~bCanChange )
        return;
    end
    
    if ( any(bLocked) && dir < 0 )
        return;
    end
    
    changedHulls = assignHull;
    if ( oldTrackHull > 0 )
        changedHulls = [changedHulls oldTrackHull];
    end
    
    if ( dir < 0 )
        % Makes sure track's start time is later than assignTime
        Families.RemoveFromTreePrune(track, trackTime);
        
        % In case trackIDs changed because of the tree removal
        track = Hulls.GetTrackID(trackHull);
        oldAssignTrack = Hulls.GetTrackID(assignHull);
    end
    
    if ( any(bLocked) )
        Tracks.LockedChangeLabel(oldAssignTrack, track, assignTime);
    else
        Tracks.ChangeLabel(oldAssignTrack, track, assignTime);
    end
end

