function ResegmentFromTree(rootTracks,preserveTracks)
    global CellHulls HashedCells CellTracks CellFamilies ConnectedDist
    
    if ( ~exist('preserveTracks','var') )
        preserveTracks = [];
    end
    
%     preserveTracks = unique([CellFamilies(preserveTracks).rootTrackID]);
%     rootTracks = unique([CellFamilies(rootTracks).rootTrackID]);
    
    checkTracks = getSubtreeTracks(rootTracks);
    cloneTracks = union(checkTracks,getSubtreeTracks(preserveTracks));
    
    startTime = min([CellTracks(checkTracks).startTime]);
    endTime = max([CellTracks(checkTracks).endTime]);
    
    for t=startTime:endTime
        % Find tracks which are missing hulls in current frame
        missedTracks = [];
        bInTracks = (t >= [CellTracks(checkTracks).startTime]) & (t < [CellTracks(checkTracks).endTime]);
        inTracks = checkTracks(bInTracks);
        for i=1:length(inTracks)
            hash = t - CellTracks(inTracks(i)).startTime + 1;
            if ( CellTracks(inTracks(i)).hulls(hash) > 0 )
                continue;
            end
            
            missedTracks = union(missedTracks, inTracks(i));
        end
        
        if ( isempty(missedTracks) )
            continue;
        end
        
%         [prevHulls bHasPrev] = getHulls(t-1, missedTracks);
%         prevTracks = missedTracks(bHasPrev);
        [prevHulls bHasPrev] = getHulls(t-1, inTracks);
        prevTracks = inTracks(bHasPrev);
        
        bestNextHulls = getBestNextHulls(prevHulls);
        
        [splitHulls prevMap repMap] = unique(bestNextHulls);
        
        addsplits = struct('curHull',{}, 'prevHulls',{}, 'newHulls',{});
        for i=1:length(splitHulls)
            splitIdx = find(bestNextHulls == splitHulls(i));
            for j=1:length(splitIdx);
                newsplit = struct('curHull',{splitHulls(i)}, 'prevHulls',{prevHulls(splitIdx)}, 'newHulls',{j});
                addsplits = [addsplits newsplit];
            end
        end
        
        for i=1:length(prevHulls)
            
        end
        
        buildEnsembleCost();
        
        % Update Tracking to next frame?
        
    end
end

function wantHulls = getBestNextHulls(hulls)
    global CellHulls
    
    wantHulls = zeros(1,length(hulls));
    [costMatrix,bFrom,bToHulls] = GetCostSubmatrix(hulls,1:length(CellHulls));
    toHulls = find(bToHulls);
    [minOut bestIdx] = min(costMatrix,[],2);
    
    wantHulls(bFrom) = toHulls(bestIdx);
end

function [hulls bHasHull] = getHulls(t, tracks)
    global HashedCells
    
    hulls = [];
    bHasHull = false(1,length(missedTracks));
    
    if ( t <= 0 || t > length(HashedCells) )
        return;
    end
    
    for i=1:length(tracks)
        hullID = GetHullID(t,tracks);
        if ( hullID == 0 )
            continue;
        end
        
        hulls = [hulls hullID];
        bHasHull(i) = 1;
    end
end

function childTracks = getSubtreeTracks(rootTracks)
    global CellTracks
    
    childTracks = rootTracks;
    while ( any(~isempty([CellTracks(childTracks).childrenTracks])) )
        newTracks = setdiff([CellTracks(childTracks).childrenTracks], childTracks);
        if ( isempty(newTracks) )
            return;
        end
        
        childTracks = union(childTracks, newTracks);
    end
end