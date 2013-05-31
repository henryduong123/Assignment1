% LockedSwapLabels(trackA, trackB, time)
%
% This function will swap the hulls of the two tracks at the given time.
% By it's nature this preserves structures because nothing but hull
% associations are modified.

function LockedSwapLabels(trackA, trackB, time)

    %% Error Check
    hullA = Tracks.GetHullID(time, trackA);
    hullB = Tracks.GetHullID(time, trackB);
    if ( hullA == 0 )
        error('Track %d has no hull to swap at time %d,', trackA, time);
    end

    if ( hullB == 0 )
        error('Track %d has no hull to swap at time %d,', trackB, time);
    end

    swapTracking(hullA, hullB);
end

% swapTracking(hullA, hullB)
%
% Currently hullA has trackA, hullB has trackB
% swap so that (hullA -> trackB) and (hullB -> trackA)
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
    
    % Swap hashed track IDs
    HashedCells{t}(hashAIdx).trackID = trackB;
    HashedCells{t}(hashBIdx).trackID = trackA;
    
    % Swap hulls in tracks
    hashTime = t - CellTracks(trackA).startTime + 1;
    CellTracks(trackA).hulls(hashTime) = hullB;
    
    hashTime = t - CellTracks(trackB).startTime + 1;
    CellTracks(trackB).hulls(hashTime) = hullA;
end
