function newPreserveTracks = FixupSingleFrame(t, preserveTracks, tEnd)
    global CellTracks HashedCells
    
    % TODO: Make this check to see if we can extend the track
    % (ie, is there a phenotype that says we shouldn't?)
    bInTracks = Helper.CheckInTracks(t, preserveTracks);
    if ( nnz(bInTracks) == 0 )
        return;
    end
    
    inPreserveTracks = preserveTracks(bInTracks);
    
    % Disconnect all tracks (t-1) -> t.
    [droppedTracks oldEdges] = chopTracks(t, inPreserveTracks);
    
    % Find best (t-1) -> t assignment (adding/splitting hulls)
    newEdges = Segmentation.ResegFromTree.FindFrameReseg(t, oldEdges);
    
    bExtendEdges = (oldEdges(:,2) == 0);
    
    % Update tracking costs and dijkstra internal state
    updateHulls = [HashedCells{t-1}.hullID];
    tHulls = [HashedCells{t}.hullID];
    
    Tracker.UpdateTrackingCosts(t-1, updateHulls, tHulls);
    
    Segmentation.ResegFromTree.UpdateDijkstraGraph(t-1);
    Segmentation.ResegFromTree.UpdateDijkstraGraph(t);
    
    % Avoid reassignment on tracks that don't exist after current frame.
    % Ignore edges that didn't have a future before for reassignment
    bReassign = false(size(newEdges,1),1);
    bChkReassign = ~bExtendEdges;
    checkTracks = droppedTracks(bChkReassign);
    
    % Use Dijkstra or just manually find best t -> (t+1) assignment, and
    % move hulls in frame t into the appropriate dropped tracks
    bLeaf = arrayfun(@(x)(isempty(CellTracks(x).childrenTracks)), checkTracks);
    bPastEnd = arrayfun(@(x)(t+1 > CellTracks(x).endTime), checkTracks);
    bReassign(bChkReassign) = (~bLeaf | ~bPastEnd);
    
    reassignEdges = newEdges(bReassign,:);
    if ( t < tEnd )
        newEdges(bReassign,:) = Segmentation.ResegFromTree.ReassignNextFrame(t, droppedTracks(bReassign), reassignEdges);
    end
    
    extendEdges = newEdges(bExtendEdges,:);
    if ( any(bExtendEdges) )
        extendLeavesForward(extendEdges, droppedTracks)
    end
    
    % Do appropriate linking up of tracks from (t-1) -> t as found above
    newPreserveTracks = Segmentation.ResegFromTree.LinkupEdges(newEdges, preserveTracks);
    
    if ( t < length(HashedCells) )
        Tracker.UpdateTrackingCosts(t, tHulls, [HashedCells{t+1}.hullID]);
    end
end

function [droppedTracks edges] = chopTracks(t, tracks)
    global CellTracks;
    
    droppedTracks = zeros(1,length(tracks));
    
    edges = [];
    % Find edges (hull-to-hull) that span t
    for i=1:length(tracks)
        chkEdge = Segmentation.ResegFromTree.GetTrackInEdge(t, tracks(i));
%         if ( isempty(chkEdge) )
%             error(['Not all preserve tracks in frame ' num2str(t) ' have edges through frame ' num2str(t)]);
%         end
        
        edges = [edges; chkEdge];
    end
    
    choppedTracks = [];
    % Drop tracks at frame t
    for i=1:length(tracks)
        choppedTracks = union(choppedTracks, Families.RemoveFromTreePrune(tracks(i), t));
    end
    
    % Associate edges with droppedTracks
    startHulls = arrayfun(@(x)(x.hulls(1)), CellTracks(choppedTracks));
    [bDropped srtIdx] = ismember(edges(:,2), startHulls);
    
%     if ( ~all(bDropped) )
%         error(['Not all preserve tracks were chopped ' num2str(t)]);
%     end
    
    droppedTracks(bDropped) = choppedTracks(srtIdx(bDropped));
end

function extendLeavesForward(extendEdges, droppedTracks)
    for i=1:size(extendEdges,1)
        pushHull = extendEdges(i,2);
        if ( pushHull == 0 )
            continue;
        end

        % Don't do anything if the push hull is on a dropped track
        pushTrack = Hulls.GetTrackID(pushHull);
        if ( any(droppedTracks == pushTrack) )
            continue;
        end

        % Tear hull off of its track and make a new one for it.
        Tracks.RemoveHullFromTrack(pushHull);
        Families.NewCellFamily(pushHull);
    end
end
