function LinkTreesForward(rootTracks)
    global CellHulls HashedCells

    leafHulls = getLeafHulls(rootTracks);
    tStart = CellHulls(leafHulls(1)).time;
    tEnd = length(HashedCells);
    
    maxFrameExt = 7;
    
    Progressbar(0);
    while ( CellHulls(leafHulls(1)).time < length(HashedCells) )
%         mitosisFam = union(preserveFamilies,[CellTracks(rootTracks).faimlyID]);
%         pathExt = findExtensions(leafHulls(1), maxFrameExt);
        
        for i=1:length(leafHulls)
            pathExt = findExtensions(leafHulls(i), maxFrameExt);
            if ( ~isempty(pathExt) )
                break;
            end
        end
        
        if ( i == length(leafHulls) )
            break;
        end
        
        [pathCosts srtidx] = sort([pathExt.cost]);
        AssignEdge(pathExt(srtidx(1)).path(1),pathExt(srtidx(1)).path(end),1);
        
        leafHulls = getLeafHulls(rootTracks);
        if ( isempty(leafHulls) )
            break;
        end
        
        Progressbar((CellHulls(leafHulls(1)).time - tStart) / (tEnd-tStart));
    end
    Progressbar(1);
end



function leafHulls = getLeafHulls(rootTracks)
    global CellFamilies CellTracks CellHulls
    
    families = unique([CellTracks(rootTracks).familyID]);
    
    leafHulls = [];
    for i=1:length(families)
        famTracks = CellFamilies(families(i)).tracks;
        for j=1:length(famTracks)
            if ( ~isempty(CellTracks(famTracks(j)).childrenTracks) )
                continue;
            end
            
            leafHulls = union(leafHulls, GetHullID(CellTracks(famTracks(j)).endTime,famTracks(j)));
        end
    end
    
    trackEnds = [CellHulls(leafHulls).time];
    [trackEnds srtidx] = sort(trackEnds);
    leafHulls = leafHulls(srtidx);
end

function extensions = findExtensions(startHull, maxExt)
    global CellHulls HashedCells CellTracks
    
    tStart = CellHulls(startHull).time;
    tEnd = min(tStart+maxExt,length(HashedCells));
    
    allPaths = {};
    buildPaths = startHull;
    
    costMatrix = GetCostMatrix();
    
    extensions = struct('cost',{}, 'endHull',{}, 'path',{});
    for t=tStart:(tEnd-1)
        if ( isempty(buildPaths) )
            break;
        end
        
        endHulls = buildPaths(:,end);
        buildPaths = [buildPaths zeros(length(endHulls),1)];
        endBuildIdx = 1;
        for i=1:length(endHulls)
            nextHulls = find(costMatrix(endHulls(i),:));
            buildPaths = buildPaths([1:(endBuildIdx-1) endBuildIdx*ones(1,length(nextHulls)) endBuildIdx+1:size(buildPaths,1)],:);
            for j=1:length(nextHulls)
                buildPaths(endBuildIdx+j-1,end) = nextHulls(j);
            end
            endBuildIdx = endBuildIdx + length(nextHulls);
        end
        
        nextHulls = buildPaths(:,end);
        for i=1:length(nextHulls)
            trackID = GetTrackID(nextHulls(i));
            if ( CellTracks(trackID).startTime ~= CellHulls(nextHulls(i)).time )
                continue;
            end
            
%             if ( ~isempty(CellTracks(trackID).parentTrack) )
%                 continue;
%             end
            
            allPaths = [allPaths {buildPaths(i,:)}];
        end
    end
    
    for i=1:length(allPaths)
        
        pathCosts = zeros(1,length(allPaths{i})-1);
        for j=1:length(pathCosts)
            pathCosts(j) = costMatrix(allPaths{i}(j),allPaths{i}(j+1));
        end
        
        extensions(i).cost = mean(pathCosts);
        extensions(i).path = allPaths{i};
        extensions(i).endHull = allPaths{i}(end);
    end
end
