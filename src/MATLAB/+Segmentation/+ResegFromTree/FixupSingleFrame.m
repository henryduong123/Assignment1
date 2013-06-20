function newPreserveTracks = FixupSingleFrame(t, preserveTracks, tEnd)
    global CellTracks HashedCells
    bInTracks = (([CellTracks(preserveTracks).startTime] <= t) & ([CellTracks(preserveTracks).endTime] >= t));
    
    if ( nnz(bInTracks) == 0 )
        return;
    end
    
    inPreserveTracks = preserveTracks(bInTracks);
    
    % Disconnect all tracks (t-1) -> t.
    [droppedTracks oldEdges] = chopTracks(t, inPreserveTracks);
    
    % Find best (t-1) -> t assignment (adding/splitting hulls)
    newEdges = Segmentation.ResegFromTree.FindFrameReseg(t, oldEdges);
    
    % Update tracking costs and dijkstra internal state
    updateHulls = [HashedCells{t-1}.hullID];
    tHulls = [HashedCells{t}.hullID];
    
    Tracker.UpdateTrackingCosts(t-1, updateHulls, tHulls);
    
    Segmentation.ResegFromTree.UpdateDijkstraGraph(t-1);
    Segmentation.ResegFromTree.UpdateDijkstraGraph(t);
    
    % Use Dijkstra or just manually find best t -> (t+1) assignment, and
    % move hulls in frame t into the appropriate dropped tracks
    endTimes = [CellTracks(droppedTracks).endTime];
    bReassign = (t < endTimes);
    
    reassignEdges = newEdges(bReassign,:);
    if ( t < tEnd )
        newEdges(bReassign) = Segmentation.ResegFromTree.ReassignNextFrame(t, droppedTracks(bReassign), reassignEdges);
    end
    
    % Do appropriate linking up of tracks from (t-1) -> t as found above
    newPreserveTracks = Segmentation.ResegFromTree.LinkupEdges(newEdges, preserveTracks);
    
    if ( t < length(HashedCells) )
        Tracker.UpdateTrackingCosts(t, tHulls, [HashedCells{t+1}.hullID]);
    end
end

function [droppedTracks edges] = chopTracks(t, tracks)
    global CellTracks;
    
    droppedTracks = [];
    
    edges = [];
    % Find edges (hull-to-hull) that span t
    for i=1:length(tracks)
        chkEdge = Segmentation.ResegFromTree.GetTrackInEdge(t, tracks(i));
        if ( isempty(chkEdge) )
            error(['Not all preserve tracks in frame ' num2str(t) ' have edges through frame ' num2str(t)]);
        end
        
        edges = [edges; chkEdge];
    end
    
    % Drop tracks at frame t
    for i=1:length(tracks)
        droppedTracks = union(droppedTracks, Families.RemoveFromTreePrune(tracks(i), t));
    end
    
    % Associate edges with droppedTracks
    startHulls = arrayfun(@(x)(x.hulls(1)), CellTracks(droppedTracks));
    [bDropped srtIdx] = ismember(edges(:,2), startHulls);
    
    if ( ~all(bDropped) )
        error(['Not all preserve tracks were chopped ' num2str(t)]);
    end
    
    edges = edges(srtIdx, :);
end
