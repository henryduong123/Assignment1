%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     This file is part of LEVer.exe
%     (C) 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function TrackBackPhenotype(leafHulls, keyframeHulls)
    global CellHulls HashedCells CellTracks
    
    
    goodTracks = struct('familyID',[], 'parentTrack',[], 'siblingTrack',[], 'childrenTracks',[], 'hulls',[], ...
                        'startTime',[], 'endTime',[], 'timeOfDeath',[], 'color',[]);
    
	backHash = HashedCells;
    
    leafHulls = unique(leafHulls);
%     keyframeHulls = unique(keyframeHulls);
%     keyframeHulls = setdiff(keyframeHulls, markedHulls);
    
    startHulls = union(leafHulls, keyframeHulls);
    
	for i=1:length(startHulls)
        goodTracks(i).hulls = startHulls(i);
        goodTracks(i).startTime = CellHulls(startHulls(i)).time;
        goodTracks(i).endTime = CellHulls(startHulls(i)).time;
    end
    
    tStart = max([CellHulls(startHulls).time]);
    
    bCurGood = ([CellHulls(startHulls).time] == tStart);
    trackHulls = startHulls(bCurGood);
    
    for i=1:length(backHash{tStart})
        idx = find(ismember(backHash{tStart}(i).hullID, startHulls));
        if ( idx > 0 )
            backHash{tStart}(i).trackID = idx;
        else
            backHash{tStart}(i).trackID = 0;
        end
    end
    
    missedHulls = [];
    Progressbar(0);
    for t=tStart:-1:2
%         % Don't track through leaf-marked hulls start new tracks for them
%         avoidHulls = leafHulls([CellHulls(leafHulls).time] == t-1);
        avoidHulls = [];
        
        if ( isempty(trackHulls) )
            break;
        end
        
        Progressbar((tStart - t + 1)/(tStart - 1));
        
%         disp(t);
        
        for i=1:length(backHash{t-1})
            idx = find(ismember(backHash{t-1}(i).hullID, startHulls));
            if ( idx > 0 )
                backHash{t-1}(i).trackID = idx;
            else
                backHash{t-1}(i).trackID = 0;
            end
        end
        
        [costMatrix, trackedHulls, nextHulls] = GetTrackingCosts(t, t-1, trackHulls, avoidHulls, CellHulls, HashedCells, CellTracks);
        if ( isempty(costMatrix) )
            break;
        end
        
        costMatrix(costMatrix == 0) = Inf;
        
        maxOcclSkip = 1;
        if ( ~isempty(missedHulls) )
            missedHulls([CellHulls(missedHulls).time] > t+maxOcclSkip) = [];
            for occlSkip=1:maxOcclSkip
                if ( t+occlSkip > length(HashedCells) )
                    break;
                end
                
                curMissHulls = missedHulls([CellHulls(missedHulls).time] == t+occlSkip);
                if ( isempty(curMissHulls) )
                    continue;
                end
                
                [occlCostMatrix, occlTrackedHulls, occlNextHulls] = GetTrackingCosts(t+occlSkip, t-1, curMissHulls, avoidHulls, CellHulls, HashedCells, CellTracks);
                occlCostMatrix(occlCostMatrix == 0) = Inf;

                if ( ~isempty(occlTrackedHulls) )
                    [newNextHulls newCols] = setdiff(occlNextHulls, nextHulls);
                    nextHulls = [nextHulls newNextHulls];
                    trackedHulls = [trackedHulls occlTrackedHulls];

                    [dump,nhidx] = ismember(occlNextHulls, nextHulls);
                    [dump,thidx] = ismember(occlTrackedHulls, trackedHulls);

                    [r c] = ndgrid(thidx, nhidx);

                    costMatrix = [costMatrix Inf*ones(size(costMatrix,1),length(newNextHulls)); Inf*ones(length(occlTrackedHulls),size(costMatrix,2)+length(newNextHulls))];
                    cidx = sub2ind(size(costMatrix),r,c);
                    costMatrix(cidx) = occlCostMatrix(:);
                end
            end
        end
        
        bAssign = assignBackTracks(t-1, costMatrix, trackedHulls, nextHulls, 0);
        
        missedHulls = trackHulls(~ismember(trackHulls, trackedHulls(any(bAssign,2))));
        trackHulls = [nextHulls(any(bAssign,1)) avoidHulls];
        trackHulls = union(trackHulls, startHulls([CellHulls(startHulls).time] == t-1));
    end
    
    Progressbar(1);
    
%     ProcessNewborns(1:length(CellFamilies), tStart);
end

function bAssign = assignBackTracks(t, costMatrix, trackedHulls, nextHulls, bPropForward)
    [minInCosts,bestIncoming] = min(costMatrix,[],1);
    [minOutCosts,bestOutgoing] = min(costMatrix,[],2);
    
    bestOutgoing  = bestOutgoing';
    bMatchedCol = false(size(bestIncoming));
    bMatched = (bestIncoming(bestOutgoing) == (1:length(bestOutgoing)));
    bMatchedCol(bestOutgoing(bMatched)) = 1;
    matchedIdx = find(bMatched);
    
    bAssign = false(size(costMatrix));
    
    % Assign matched edges
	for i=1:length(matchedIdx)
        if ( minOutCosts(matchedIdx(i)) == Inf )
            continue;
        end
        
        assignHull = nextHulls(bestOutgoing(matchedIdx(i)));
        extHull = trackedHulls(matchedIdx(i));
        
%         [tracks, hash] = extendBackTrack(extHull, assignHull, tracks, hash);
        assignHullToTrack(t, assignHull, extHull, bPropForward);
        bAssign(matchedIdx(i), bestOutgoing(matchedIdx(i))) = 1;
	end
    
%     costMatrix(bMatched,:) = Inf;
%     costMatrix(:,bMatchedCol) = Inf;
%     
%     [minCost minIdx] = min(costMatrix(:));
%     % Patch up whatever other nurtureTracks we can
%     while ( minCost ~= Inf )
%         [r c] = ind2sub(size(costMatrix), minIdx);
%         assignHull = nextHulls(c);
%         extHull = trackedHulls(r);
%         
% %         [tracks, hash] = extendBackTrack(extHull, assignHull, tracks, hash);
%         assignHullToTrack(t, assignHull, extHull, bPropForward);
%         bAssign(r,c) = 1;
%         
%         costMatrix(r,:) = Inf;
%         costMatrix(:,c) = Inf;
%         
%         [minCost minIdx] = min(costMatrix(:));
%     end
end

function changedHulls = assignHullToTrack(t, hull, extHull, bUseChangeLabel)
    global HashedCells
    
    % Get track to which we will assign hull from extHulls
    track = GetTrackID(extHull);
    
    oldHull = [];
    changedHulls = [];
    
	% Get old hull - track assignments
    bOldHull = [HashedCells{t}.trackID] == track;
    if ( any(bOldHull) )
        oldHull = HashedCells{t}(bOldHull).hullID;
    end
    
    oldTrack = HashedCells{t}([HashedCells{t}.hullID] == hull).trackID;

    % Hull - track assignment is unchanged
    if ( oldHull == hull )
        return;
    end

    if ( bUseChangeLabel )
        exchangeTrackLabels(t, oldTrack, track);
        return;
    end
    
    if ( ~isempty(oldHull) )
        % Swap track assignments
        swapTracking(t, oldHull, hull, track, oldTrack);
        changedHulls = [oldHull hull];
    else
        % Add hull to track
        RemoveHullFromTrack(hull, oldTrack, 1, -1);
        
        % Some RemoveHullFromTrack cases cause track to be changed
        track = GetTrackID(extHull);
        ExtendTrackWithHull(track, hull);
        changedHulls = hull;
    end
end

% Currently hullA has trackA, hullB has trackB
% swap so that hullA gets trackB and hullB gets trackA
function swapTracking(t, hullA, hullB, trackA, trackB)
    global HashedCells CellTracks
    
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
    global CellTracks CellFamilies
    
    RehashCellTracks(track, CellTracks(track).startTime);
    RehashCellTracks(oldTrack, CellTracks(oldTrack).startTime);
    
    if ( CellTracks(track).endTime >= t )
        RemoveFromTree(t, track, 'no');
    end
    
    if ( CellTracks(oldTrack).startTime < t )
        newFamID = RemoveFromTree(t, oldTrack, 'no');
        removeIfEmptyTrack(oldTrack);
        
        oldTrack = CellFamilies(newFamID).rootTrackID;
    end
    
    ChangeLabel(t, oldTrack, track);
end

function removeIfEmptyTrack(track)
    global CellTracks
    
    RehashCellTracks(track);
    if ( ~isempty(CellTracks(track).hulls) )
        return;
    end
    
    childTracks = CellTracks(track).childrenTracks;
    for i=1:length(childTracks)
        RemoveFromTree(CellTracks(childTracks(i)).startTime, childTracks(i), 'no');
    end

    RemoveTrackFromFamily(track);
    ClearTrack(track);
end

