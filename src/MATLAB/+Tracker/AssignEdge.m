% Assign the edge from trackHull to assignHull, this changes the track
% assignment for assignHull such that it will be on the same track as
% trackHull. the bUseChangeLabel option propagates this change over the
% entire track, either forward or backward depending on the relative times
% of trackHull and assignHull

function changedHulls = AssignEdge(trackHull, assignHull, bUseChangeLabel)
    global CellHulls;
    
    changedHulls = [];
    
     % Get track to which we will assign hull from trackHull
    track = Hulls.GetTrackID(trackHull);
    
    assignTime = CellHulls(assignHull).time;
    trackTime = CellHulls(trackHull).time;
    
    oldTrackHull = getHull(assignTime, track);
    oldAssignTrack = Hulls.GetTrackID(assignHull);
    
    dir = sign(assignTime - trackTime);
    
    % Hull - track assignment is unchanged
    if ( oldTrackHull == assignHull )
        return;
    end
    
    if ( bUseChangeLabel )
        if ( dir >= 0 )
            exchangeTrackLabels(assignTime, oldAssignTrack, track);
        else
            exchangeTrackLabels(trackTime, track, oldAssignTrack);
        end
        return;
    end
    
    if ( ~isempty(oldTrackHull) )
        % Swap track assignments for a single frame
        swapTracking(oldTrackHull, assignHull);
        changedHulls = [oldTrackHull assignHull];
    else
        % Add hull to track
        %TODO Fix func call
        [bDump,splitTrack] = Tracks.RemoveHullFromTrack(assignHull, oldAssignTrack, 1);
        
        % Some RemoveHullFromTrack cases cause track to be changed
        track = Hulls.GetTrackID(trackHull);
        oldTrackHull = getHull(assignTime, track);
        if ( ~isempty(oldTrackHull) )
            if ( isempty(splitTrack) )
                error('Non-empty old cell ID without track split, cannot repair change');
            end
            
            % Special case: a split-track due to hull removal has caused us to want to
            % put assignHull on a track which now exists in this frame (oldTrackHull).
            % we first extend splitTrack with assignHull, then swap tracking in this frame.
            Tracks.ExtendTrackWithHull(splitTrack, assignHull);
            swapTracking(oldTrackHull, assignHull);
            changedHulls = [oldTrackHull assignHull];
        else
            Tracks.ExtendTrackWithHull(track, assignHull);
            changedHulls = assignHull;
        end
    end
    
end

function hull = getHull(t, track)
    global HashedCells
    
    hull = [];
    
    hullIdx = find([HashedCells{t}.trackID] == track,1,'first');
    if ( isempty(hullIdx) )
        return;
    end
    
    hull = HashedCells{t}(hullIdx).hullID;
end

% Currently hullA has trackA, hullB has trackB
% swap so that hullA gets trackB and hullB gets trackA
function swapTracking(hullA, hullB)
    global CellHulls HashedCells CellTracks
    
    t = CellHulls(hullA).time;
    
    if ( t ~= CellHulls(hullB).time )
        error('Attempt to swap tracking information for hulls in different frames!');
    end
    
    trackA = Hulls.GetTrackID(hullA);
    trackB = Hulls.GetTrackID(hullB);
    
    hashAIdx = ([HashedCells{t}.hullID] == hullA);
    hashBIdx = ([HashedCells{t}.hullID] == hullB);
    
    % Swap track IDs
    HashedCells{t}(hashAIdx).trackID = trackB;
    HashedCells{t}(hashBIdx).trackID = trackA;
    
    % Swap hulls in tracks
    hashTime = t - CellTracks(trackA).startTime + 1;
    CellTracks(trackA).hulls(hashTime) = hullB;
    
    hashTime = t - CellTracks(trackB).startTime + 1;
    CellTracks(trackB).hulls(hashTime) = hullA;
end

function exchangeTrackLabels(t, oldTrack, track)
    Tracks.ChangeTrackID(t, oldTrack, track); %TODO fix call
end

function removeIfEmptyTrack(track)
    global CellTracks
    
    Tracks.RehashCellTracks(track);
    if ( ~isempty(CellTracks(track).hulls) )
        return;
    end
    
    childTracks = CellTracks(track).childrenTracks;
    for i=1:length(childTracks)
        %TODO fix func call
        Families.RemoveFromTree(CellTracks(childTracks(i)).startTime, childTracks(i), 'no');
    end

    Families.RemoveTrackFromFamily(track);
    Tracks.ClearTrack(track);
end