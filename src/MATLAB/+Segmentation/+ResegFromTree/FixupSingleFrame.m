function newPreserveTracks = FixupSingleFrame(t, preserveTracks, tEnd, viewLims)
    global CellTracks HashedCells
    
    newPreserveTracks = preserveTracks;
    bFrozen = Helper.CheckTreeFrozen(preserveTracks);
    
    preserveTracks = preserveTracks(~bFrozen);
    
    bInTracks = Helper.CheckInTracks(t, preserveTracks);
    if ( nnz(bInTracks) == 0 )
        return;
    end
    
    inPreserveTracks = preserveTracks(bInTracks);
    
    % Disconnect all tracks (t-1) -> t.
    [droppedTracks oldEdges] = chopTracks(t, inPreserveTracks);
    bIgnoreEdges = Segmentation.ResegFromTree.CheckIgnoreTracks(t, inPreserveTracks, viewLims);
    
    % This attempts to keep track of what we think we've correctly resegmented
    clearEdgeResegInfo(oldEdges(~bIgnoreEdges,:));
    
    % Find best (t-1) -> t assignment (adding/splitting hulls)
    newEdges = Segmentation.ResegFromTree.FindFrameReseg(t, oldEdges, bIgnoreEdges);
    
    allEdges = zeros(size(oldEdges));
    % Find and fixup conflicts from "ignoring" edges
    allEdges(bIgnoreEdges,:) = fixupConflictingEdges(t, bIgnoreEdges, newEdges, oldEdges, droppedTracks);
    allEdges(~bIgnoreEdges,:) = newEdges;
    
    bExtendEdges = (oldEdges(:,2) == 0);
    bValidTracks = (droppedTracks > 0).';
    if ( ~all(bValidTracks == (~bExtendEdges)) )
        error('Valid track and extension mismatch');
    end
    
    % Update tracking costs and dijkstra internal state
    updateHulls = [HashedCells{t-1}.hullID];
    tHulls = [HashedCells{t}.hullID];
    
    Tracker.UpdateTrackingCosts(t-1, updateHulls, tHulls);
    
    Segmentation.ResegFromTree.UpdateDijkstraGraph(t-1);
    Segmentation.ResegFromTree.UpdateDijkstraGraph(t);
    
    % Match edges and droppedTracks in case some of them don't end up in
    % reassignment, also handle tear-off of any extension edge targets.
    [allEdges bReassign] = extendLeavesForward(t, allEdges, droppedTracks);
    
    % Use Dijkstra or just manually find best t -> (t+1) assignment, and
    % move hulls in frame t into the appropriate dropped tracks
    reassignEdges = allEdges(bReassign,:);
    if ( (t < tEnd) && ~isempty(reassignEdges) )
        allEdges(bReassign,:) = Segmentation.ResegFromTree.ReassignNextFrame(t, droppedTracks(bReassign), reassignEdges);
    end
    
    % Do appropriate linking up of tracks from (t-1) -> t as found above
    newPreserveTracks = Segmentation.ResegFromTree.LinkupEdges(allEdges, preserveTracks);
    
    % This attempts to keep track of what we think we've correctly resegmented
    setEdgeResegInfo(newEdges);
    
    if ( t < length(HashedCells) )
        Tracker.UpdateTrackingCosts(t, tHulls, [HashedCells{t+1}.hullID]);
    end
end

function [droppedTracks edges] = chopTracks(t, tracks)
    global CellTracks;
    
    droppedTracks = zeros(1,length(tracks));
    
    edges = zeros(length(tracks),2);
    % Find edges (hull-to-hull) that span t
    for i=1:length(tracks)
        chkEdge = Segmentation.ResegFromTree.GetTrackInEdge(t, tracks(i));
        edges(i,:) = chkEdge;
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

function setEdgeResegInfo(edges)
    global CellTracks ResegLinks
    
    bValidEdges = all(edges ~= 0, 2);
    validEdges = edges(bValidEdges,:);
    
    trackIDs = Hulls.GetTrackID(validEdges(:,1));
    familyIDs = [CellTracks(trackIDs).familyID];
    
    for i=1:size(validEdges,1)
        ResegLinks(validEdges(i,1),validEdges(i,2)) = familyIDs(i);
    end
end

function clearEdgeResegInfo(edges)
    global ResegLinks
    
    nzNextHulls = edges((edges(:,2) ~= 0),2);
    ResegLinks(:,nzNextHulls) = 0;
end

function fixedEdges = fixupConflictingEdges(t, bIgnored, newEdges, oldEdges, droppedTracks)
    global CellTracks
    
    ignoredEdges = oldEdges(bIgnored,:);
    oldLookup = find(~bIgnored);
    
    [bNeedsFix conflictIdx] = ismember(ignoredEdges(:,2), newEdges(:,2));
    bNeedsFix = (bNeedsFix & (ignoredEdges(:,2) ~= 0));
    
    % Current mitosis events should be preserved anyway so only worry about next frame mitoses
    bValidDropped = (droppedTracks ~= 0);
    bMitNext = false(length(droppedTracks),1);
    bMitNext(bValidDropped) = (arrayfun(@(x)((~isempty(x.childrenTracks)) && (x.endTime == t)), CellTracks(droppedTracks(bValidDropped))));
    
    fixedEdges = ignoredEdges;
    
    fixIdx = find(bNeedsFix);
    conflictIdx = conflictIdx(bNeedsFix);
    for i=1:length(fixIdx)
        fixedEdges(fixIdx,2) = 0;
        % Swap mitosis events if we're going to take a mitosis from an
        % ignored track and there's nowhere else for original mitosis
        if ( bMitNext(oldLookup(conflictIdx(i))) && (~any(newEdges(:,2) == oldEdges(oldLookup(conflictIdx(i)),2))) )
            fixedEdges(fixIdx,2) = oldEdges(oldLookup(conflictIdx(i)),2);
        end
    end
end

% Deal with tracks that aren't going to go through reassignment code
% because of extension or single-frame droppedTracks
function [edges bReassign] = extendLeavesForward(t, edges, droppedTracks)
    global CellTracks
    bValidNext = (edges(:,2) > 0);
    
    nextTracks = -1*ones(size(edges,1),1);
    
    nextHulls = edges(bValidNext,2);
    nextTracks(bValidNext) = Hulls.GetTrackID(nextHulls);
    
    sortEdges = zeros(size(edges,1),1);
    [bInDropped nextIdx] = ismember(droppedTracks, nextTracks);
    sortEdges(bInDropped) = nextIdx(bInDropped);
    sortEdges(~bInDropped) = setdiff(1:length(droppedTracks), nextIdx);
    
    edges = edges(sortEdges,:);
    
    bLeaf = false(size(edges,1),1);
    bPastEnd = false(size(edges,1),1);
    
    bValidTracks = (droppedTracks > 0).';
    bLeaf(bValidTracks) = arrayfun(@(x)(isempty(CellTracks(x).childrenTracks)), droppedTracks(bValidTracks));
    bPastEnd(bValidTracks) = arrayfun(@(x)(t+1 > CellTracks(x).endTime), droppedTracks(bValidTracks));
    
    bReassign = bValidTracks & (~bLeaf | ~bPastEnd);
    
    extendIdx = find(~bReassign);
    for i=1:length(extendIdx)
        pushHull = edges(extendIdx(i),2);
        if ( pushHull == 0 )
            continue;
        end

        pushTrack = Hulls.GetTrackID(pushHull);
        trackIdx = find((droppedTracks == pushTrack), 1, 'first');
        if ( ~isempty(trackIdx) )
            continue;
        end
        
        % Tear hull off of its track and make a new one for it.
        Tracks.RemoveHullFromTrack(pushHull);
        newFam = Families.NewCellFamily(pushHull);
    end
end
