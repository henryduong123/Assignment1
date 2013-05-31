function newEdges = ReassignNextFrame(t, droppedTracks, newEdges)
    global CellTracks CellHulls 
    
    if ( length(droppedTracks) ~= size(newEdges,1) )
        error('There are too few edges to preserve structure!');
    end
    
    % Use Dijkstra to assign t->t+1 edges (except mitosis edges, don't
    % break those!)
    
    assignToTrack = zeros(size(newEdges,1),1);
    
	termHulls = zeros(1,size(newEdges,1));
    for i=1:length(droppedTracks)
        termHulls(i) = Helper.GetNearestTrackHull(droppedTracks(i), t+1, +1);
    end
    
    bCurrentMitosis = (arrayfun(@(x)((~isempty(x.childrenTracks)) & (x.endTime == t)), CellTracks(droppedTracks)));
    
    if ( any((termHulls == 0) & ~bCurrentMitosis) )
        error('There are no hulls on dropped track after frame t!');
    end
    
    forwardCosts = Inf*ones(size(newEdges,1), size(newEdges,1));
    
    % Use Dijkstra to find other costs
    maxT = max([CellHulls(termHulls(~bCurrentMitosis)).time]);
    
    % Handle the case that only mitosis event options exist on
    if ( isempty(maxT) )
        maxT = max(horzcat(CellHulls(newEdges(:,2)).time) + 5);
    end
    
    for i=1:size(newEdges,1)
        extendHull = newEdges(i,2);
        if ( extendHull == 0 )
            extendHull = newEdges(i,1);
        end
        
        maxExt = maxT - CellHulls(extendHull).time + 1;
        
        [endpaths endCosts] = mexDijkstra('matlabExtend', extendHull, maxExt, @(x,y)(any(y==termHulls)), 1, 0);
        lastHulls = cellfun(@(x)(x(end)), endpaths);
        [bFoundPath arrIdx] = ismember(termHulls, lastHulls);
        
        forwardCosts(i,bFoundPath) = endCosts(arrIdx(bFoundPath));
    end
    
    % Deal with mitosis events
    currentMitosis = find(bCurrentMitosis);
    for i=1:length(currentMitosis)
        childrenTracks = CellTracks(droppedTracks(currentMitosis(i))).childrenTracks;
        leftHull = Helper.GetNearestTrackHull(childrenTracks(1), t+1, +1);
        rightHull = Helper.GetNearestTrackHull(childrenTracks(2), t+1, +1);
        
        if ( leftHull == 0 || rightHull == 0 )
            error('Badly defined mitosis event, parent hull not followed by two child hulls');
        end
        
        totalCosts = Inf*ones(size(newEdges,1),1);
        bRealHullIdx = (newEdges(:,2) ~= 0);
        
        mitCosts = Segmentation.ResegFromTree.GetNextCosts(t,newEdges(bRealHullIdx,2), [leftHull rightHull]);
        totalCosts(bRealHullIdx) = sum(mitCosts,2);
        
        [minCost bestFromIdx] = min(totalCosts);
        if ( isinf(minCost) )
            error('There is no hull in frame t from which to build the mitosis event');
        end
        
        forwardCosts(bestFromIdx,:) = Inf;
        forwardCosts(:,currentMitosis(i)) = Inf;
        forwardCosts(bestFromIdx,currentMitosis(i)) = 1;
    end
    
    assignIdx = assignmentoptimal(forwardCosts);
    notAssigned = find(assignIdx == 0);
    if ( ~isempty(notAssigned) )
        % If all else fails assign arbitrarily
        for i=1:length(notAssigned)
            bInf = isinf(forwardCosts(notAssigned(i),:));
            forwardCosts(notAssigned(i),bInf) = 1e10;
        end
        
        assignIdx = assignmentoptimal(forwardCosts);
        if ( any(assignIdx == 0) )
            error('Unable to assign all t->t+1 edges');
        end
    end
    
    for i=1:size(newEdges,1)
        if ( newEdges(i,2) == 0 )
            newEdges(i,2) = termHulls(assignIdx(i));
            continue;
        end
        
        assignToTrack(i) = droppedTracks(assignIdx(i));
    end
    
%     % Assign all hulls to next frames
%     [bOnTrack trackIdx] = ismember(Hulls.GetTrackID(newEdges(bnzEdges,2)), droppedTracks);
%     trackIdx(~bOnTrack) = setdiff(1:length(droppedTracks),trackIdx(bOnTrack));
%     assignToTrack = droppedTracks(trackIdx);
    
    relinkTracks = cell(length(assignToTrack), 1);
    for i=1:length(assignToTrack)
        if ( assignToTrack(i) == 0 )
            continue;
        end
        
        curTrack = Hulls.GetTrackID(newEdges(i,2));
        if ( curTrack == assignToTrack(i) )
            continue;
        end
        
        curHull = Tracks.GetHullID(t, assignToTrack(i));
        if ( curHull ~= 0 )
            relinkTracks{i} = Tracks.RemoveHullFromTrack(curHull);
            Families.NewCellFamily(curHull);
        end
        
        oldDropped = Tracks.RemoveHullFromTrack(newEdges(i,2));
        
        assignIdx = find(curTrack == assignToTrack);
        if ( ~isempty(assignIdx) )
            relinkTracks{assignIdx} = oldDropped;
        end
        
        Tracks.AddHullToTrack(newEdges(i,2), assignToTrack(i));
    end
    
    for i=1:length(relinkTracks)
        if ( isempty(relinkTracks{i}) )
            continue;
        end
        
        Families.ReconnectParentWithChildren(assignToTrack(i), relinkTracks{i});
    end
end