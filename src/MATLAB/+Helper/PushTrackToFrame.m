
function PushTrackToFrame(trackID, frameTime)
    global CellFamilies CellTracks CellHulls HashedCells
    
    bLockedHulls = false(1,length(CellHulls));
    
    bLockedFamilies = ([CellFamilies.bLocked] > 0);
    lockedTracks = [CellFamilies(bLockedFamilies).tracks];
    lockTrackHulls = [CellTracks(lockedTracks).hulls];
    nzHulls = lockTrackHulls(lockTrackHulls > 0);
    bLockedHulls(nzHulls) = 1;
    
    costMatrix = Tracker.GetCostMatrix();
    
    startHull = CellTracks(trackID).hulls(1);
    termHulls = [HashedCells{frameTime}.hullID];
    bLockedTerms = bLockedHulls(termHulls);
    
    d = dijkstra_sp(costMatrix, startHull);
    
    dTerms = d(termHulls);
    [sortDist srtIdx] = sort(dTerms);
    
    bValid = ~isinf(sortDist);
    checkIdx = srtIdx(bValid);
    if ( isempty(checkIdx) )
        % Try to add a hull somewhere
        error('No hulls available to add');
        return;
    end
    
    bUnlocked = ~bLockedTerms(checkIdx);
    unlockedHulls = termHulls(checkIdx(bUnlocked));
    if ( isempty(unlockedHulls) )
        % Find locked hull to split?
        error('Should probably split a hull here');
        return;
    end
    
    endHull = unlockedHulls(1);
    
    time = CellHulls(endHull).time;
    oldTrackID = Hulls.GetTrackID(endHull);
    Tracks.ChangeLabel(oldTrackID, trackID, time);
end