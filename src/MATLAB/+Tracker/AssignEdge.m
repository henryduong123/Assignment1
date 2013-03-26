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
    
    % Check family locks
    assignFamilyID = CellTracks(Hulls.GetTrackID(assignHull)).familyID;
    trackFamilyID = CellTracks(Hulls.GetTrackID(trackHull)).familyID;
    
    if ( CellFamilies(assignFamilyID).bLocked || CellFamilies(trackFamilyID).bLocked )
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
    
    Tracks.ChangeLabel(oldAssignTrack, track, assignTime);
end

