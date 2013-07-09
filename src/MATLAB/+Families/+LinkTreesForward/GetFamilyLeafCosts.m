function  leafGraphHandle = GetFamilyLeafCosts(stopTime)
    global CellFamilies CellHulls
    
    leafGraphHandle = mexGraph('createGraph', length(CellHulls));
    
    for i=1:length(CellFamilies)
        if ( isempty(CellFamilies(i).startTime) )
            continue;
        end
        
        if ( CellFamilies(i).bLocked )
            continue;
        end
        
        if ( CellFamilies(i).startTime > stopTime )
            continue;
        end
        
        addFamilyEdges(i, leafGraphHandle, stopTime);
    end
    
end

function addFamilyEdges(familyID, leafGraphHandle, stopTime)
    global CellFamilies
    
    rootTrack = CellFamilies(familyID).rootTrackID;
    
    recursiveLeafCosts(rootTrack, leafGraphHandle, stopTime);
end

function [leafHulls leafCosts] = recursiveLeafCosts(trackID, leafGraphHandle, stopTime)
    global CellTracks
    
    leafHulls = [];
    leafCosts = [];
    
    [localCost endHull bStopHere] = singleTrackCost(trackID, stopTime);
    
    rootHull = CellTracks(trackID).hulls(1);
    
    if ( bStopHere || isempty(CellTracks(trackID).childrenTracks) )
        
        if ( endHull ~= rootHull )
            mexGraph('setEdge', leafGraphHandle, rootHull, endHull, localCost);
        end
        
        leafHulls = endHull;
        leafCosts = localCost;
        return;
    end
    
    childTracks = CellTracks(trackID).childrenTracks;
    for i=1:length(childTracks)
        childStart = CellTracks(childTracks(i)).hulls(1);
        edgeCost = mexDijkstra('edgeCost', endHull, childStart);
        
        [childLeafHulls childLeafCosts] = recursiveLeafCosts(childTracks(i), leafGraphHandle, stopTime);
        
        leafHulls = [leafHulls childLeafHulls];
        leafCosts = [leafCosts childLeafCosts + edgeCost + localCost];
    end
    
    mexGraph('setEdgesOut', leafGraphHandle, rootHull, leafHulls, leafCosts);
end

function [trackCost endHull bStop] = singleTrackCost(trackID, stopTime)
    global CellTracks CellHulls
    
    hullList = CellTracks(trackID).hulls;
    
    endHull = hullList(end);
    
    nzHullList = hullList(hullList > 0);
    nzHullTimes = [CellHulls(nzHullList).time];
    
    bStop = any(nzHullTimes == stopTime);
    
    bKeep = (nzHullTimes <= stopTime);
    nzHullList = nzHullList(bKeep);
    
    trackCost = 0;
    for i=1:(length(nzHullList)-1)
        nextCost = mexDijkstra('edgeCost', nzHullList(i), nzHullList(i+1));
        if ( ~(nextCost) )
            maxFrameExt =  (CellHulls(nzHullList(i+1)).time - CellHulls(nzHullList(i)).time + 1);
            % Try to find shortest graph-path to here
            [pathExt nextCost] = mexDijkstra('matlabExtend', nzHullList(i), maxFrameExt, @(x,y)(y==nzHullList(i+1)));
            if ( isempty(nextCost) )
                trackCost = Inf;
                return;
            end
        end
        trackCost = trackCost + nextCost;
    end
end

