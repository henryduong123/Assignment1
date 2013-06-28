% LockedChangeLabel(currentTrack, desiredTrack, time)
%
% This function attempts to execute a ChangeLabel from current -> desired
% such that the structures of any affected locked-trees are preserved.
%
% This means that the change will move only one hull from one
% track to the other, rather than changing the entire track.

function LockedChangeLabel(currentTrack, desiredTrack, time)
    
    % Completely cop-out if we can't preserve structure
    [bLocked bCanChange] = Tracks.CheckLockedChangeLabel(currentTrack, desiredTrack, time);
    if ( ~any(bLocked) || ~bCanChange )
        error('Cannot avoid affecting tree structure, use standard ChangeLabel');
    end
    
    changeHull = Helper.GetNearestTrackHull(currentTrack, time, 0);
    replaceHull = Helper.GetNearestTrackHull(desiredTrack, time, 0);
    
    if ( changeHull == 0 )
        error('Track ID change must have hull at current time');
    end
    
    lockedTracks = [currentTrack desiredTrack];
    lockedTracks = lockedTracks(bLocked);
    
    [nextHulls preserveTracks] = chopTracks(time+1, lockedTracks);
    [droppedHulls oldTracks] = chopTracks(time, lockedTracks);
    
    bRemoveChanged = (droppedHulls ~= changeHull);
    droppedHulls = droppedHulls(bRemoveChanged);
    oldTracks = oldTracks(bRemoveChanged);
    
    changeTrack = Hulls.GetTrackID(changeHull);
    Tracks.ChangeLabel(changeTrack, desiredTrack, time);
    
    % Cheat and just use oldTrack to preserve parent relationship if
    % necessary
    repIdx = find(droppedHulls == replaceHull);
    if ( ~isempty(repIdx) && (oldTracks(repIdx) ~= currentTrack) )
        droppedHulls(repIdx) = changeHull;
    end
    
    relinkHulls(droppedHulls, oldTracks);
    relinkHulls(nextHulls, preserveTracks);
end

function relinkHulls(droppedHulls, oldTracks)
    targetList = [];
    relinkList = {};
    
    for i=1:length(droppedHulls)
        targetIdx = find(targetList == oldTracks(i));
        if ( isempty(targetIdx) )
            targetList = [targetList; oldTracks(i)];
            relinkList = [relinkList; {droppedHulls(i)}];
        else
            relinkList{targetIdx} = [relinkList{targetIdx} droppedHulls(i)];
        end
    end
    
    for i=1:length(targetList)
        track1 = Hulls.GetTrackID(relinkList{i}(1));
        if ( length(relinkList{i}) > 1 )
            track2 = Hulls.GetTrackID(relinkList{i}(2));
            Families.ReconnectParentWithChildren(targetList(i), [track1 track2]);
        else
            Tracks.ChangeLabel(track1, targetList(i));
        end
    end
end

% Slice tracks at t
function [droppedHulls oldTracks] = chopTracks(t, tracks)
    global CellTracks;
    
    oldTracks = [];
    droppedTracks = [];
    
    removeTracks = tracks;
    
    associatedTracks = tracks;
    associatedTracks = [tracks CellTracks(tracks).childrenTracks];
    associatedTracks = [associatedTracks CellTracks(tracks).siblingTrack];
    
    % Find tracks the frame t hulls point to
    hullToTrackList = zeros(length(associatedTracks),2);
    for i=1:length(associatedTracks)
        prevHull = getPreviousFamilyHull(associatedTracks(i), t-1);
        hullToTrackList(i,1) = Helper.GetNearestTrackHull(associatedTracks(i), t, +1);
        
        if ( prevHull == 0 )
            hullToTrackList(i,2) = associatedTracks(i);
        else
            hullToTrackList(i,2) = Hulls.GetTrackID(prevHull);
        end
        
        if ( CellTracks(associatedTracks(i)).startTime == t )
            removeTracks = [removeTracks associatedTracks(i)];
        end
    end
    
    % Drop tracks at frame t
    for i=1:length(removeTracks)
        droppedTracks = [droppedTracks, Families.RemoveFromTreePrune(removeTracks(i), t)];
    end
    
    droppedTracks = unique(droppedTracks);
    
    % Associate edges with droppedTracks
    droppedHulls = arrayfun(@(x)(x.hulls(1)), CellTracks(droppedTracks));
    [bDropped srtIdx] = ismember(droppedHulls, hullToTrackList(:,1));
    
    oldTracks = transpose(hullToTrackList(srtIdx, 2));
end

function trackEdge = getTrackLongEdge(tStart, tEnd, trackID)
    global CellTracks
    
    trackEdge = [];
    
    if ( CellTracks(trackID).startTime > tEnd || CellTracks(trackID).endTime < tEnd )
        return;
    end
    
    prevHull = getPreviousFamilyHull(trackID, tStart);
    nextHull = Helper.GetNearestTrackHull(trackID, tEnd, +1);
    
    if ( prevHull == 0 )
        return;
    end
    
    if ( nextHull == 0 )
        return;
    end
    
    trackEdge = [prevHull nextHull];
end

function nearestHull = getPreviousFamilyHull(trackID, t)
    global CellTracks
    
    chkTrackID = trackID;
    while ( ~isempty(chkTrackID) )
        nearestHull = Helper.GetNearestTrackHull(chkTrackID, t, -1);
        if ( nearestHull > 0)
            return;
        end
        
        chkTrackID = CellTracks(chkTrackID).parentTrack;
    end
end
