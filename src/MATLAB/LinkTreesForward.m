function LinkTreesForward(rootTracks)
    global CellHulls HashedCells Costs

    leafHulls = getLeafHulls(rootTracks);
    tStart = CellHulls(leafHulls(1)).time;
    tEnd = length(HashedCells);
    
    maxFrameExt = 7;
    
    lookupStart = sparse([],[],[], 1,size(Costs,1), round(0.01*size(Costs,1)));
    lookupBack = sparse([],[],[], 1,size(Costs,1), round(0.01*size(Costs,1)));
    extLookup = {};
    extensions = struct('extendEdge',{}, 'extCost',{}, 'extPath',{}, 'trackCost',{}, 'trackHull',{});
    
    costMatrix = GetCostMatrix();
    
    tic;
    Progressbar(0);
    i = 1;
    checkExtHulls = leafHulls;
    while ( i <= length(checkExtHulls) )
        if ( CellHulls(checkExtHulls(i)).time >= tEnd )
            i = i + 1;
            continue;
        end
        
        [pathExt pathCost] = dijkstraSearch(checkExtHulls(i), costMatrix, @checkExtension, maxFrameExt);
        
        endHulls = zeros(1,length(pathExt));
        for j=1:length(pathExt)
            endHulls(j) = pathExt{j}(end);
        end
        
        extHulls = unique(endHulls);
        extTracks = GetTrackID(extHulls);
        
        for j=1:length(extHulls)
            nextLeaves = getLeafHulls(extTracks(j));
            
            extIdx = find(endHulls == extHulls(j));
            for k=1:length(extIdx)
                for l = 1:length(nextLeaves)
                    if ( ~lookupStart(checkExtHulls(i)) )
                        extLookup = [extLookup {[]}];
                        lookupStart(checkExtHulls(i)) = length(extLookup);
                    end
                    
                    trackCost = calcTrackCost(extHulls(j),nextLeaves(l));
                    
                    nex = struct('extendEdge',{[checkExtHulls(i) nextLeaves(l)]}, ...
                                 'extCost',{pathCost(extIdx(k))}, ...
                                 'extPath',{pathExt{extIdx(k)}}, ...
                                 'trackCost',{trackCost}, ...
                                 'trackHull',{extHulls(j)});
                    
                    extensions = [extensions nex];
                    
                    
                    hashIdx = lookupStart(checkExtHulls(i));
                    extLookup{hashIdx} = [extLookup{hashIdx} length(extensions)];
                end
            end
            
            checkExtHulls = [checkExtHulls setdiff(nextLeaves,checkExtHulls)];
        end
        
        Progressbar((i/length(checkExtHulls))/2);
        
        i = i + 1;
    end
    
    extGraph = sparse([],[],[], size(Costs,1),size(Costs,1), round(0.01*size(Costs,1)));
    extMap = sparse([],[],[], size(Costs,1),size(Costs,1), round(0.01*size(Costs,1)));
    for i=1:length(extensions)
        extGraph(extensions(i).extendEdge(1),extensions(i).extendEdge(2)) = extensions(i).extCost + extensions(i).trackCost;
        extMap(extensions(i).extendEdge(1),extensions(i).extendEdge(2)) = i;
    end
    
    leafTimes = [CellHulls(leafHulls).time];
    [dump srtidx] = sort(leafTimes);
    
    leafHulls = leafHulls(srtidx);
    for i=1:length(leafHulls)
        % Only check best-to-end for now
        [endpaths endcosts] = dijkstraSearch(leafHulls(i), extGraph, @checkFullExt, Inf);
        if ( isempty(endcosts) )
            continue;
        end
        
        [mincost minidx] = min(endcosts);
        for j=1:(length(endpaths{minidx})-1)
            startHull = endpaths{minidx}(j);
            finalHull = endpaths{minidx}(j+1);
            linkupHull = extensions(extMap(startHull,finalHull)).extPath(end);
            
            AssignEdge(linkupHull, startHull, 1);
            extGraph(:,finalHull) = 0;
        end
        
        Progressbar(0.5 + ((i/length(leafHulls))/2));
    end
    
    Progressbar(1);

    toc;
end

function cost = calcTrackCost(startHull, endHull)
    global CellHulls CellTracks
    
    costMatrix = GetCostMatrix();
    
    cost = 0;
    backHull = endHull;
    while ( backHull ~= startHull )
        trackID = GetTrackID(backHull);
        curHash = CellHulls(backHull).time - CellTracks(trackID).startTime + 1;
        nzHullIdx = find(CellTracks(trackID).hulls(1:(curHash-1)),1,'last');
        nzHull = CellTracks(trackID).hulls(nzHullIdx);
        if ( isempty(nzHullIdx) )
            parentTrackID = CellTracks(trackID).parentTrack;
            if ( ~isempty(parentTrackID) )
                nzHullIdx = find(CellTracks(parentTrackID).hulls,1,'last');
                nzHull = CellTracks(parentTrackID).hulls(nzHullIdx);
            else
                error('startHull is not in same family');
            end
        end
        if ( ~(costMatrix(nzHull,backHull)) )
            error(['cost(' nzHull ',' backHull ') is infinite']);
        end
        cost = cost + costMatrix(nzHull,backHull);
        
        backHull = nzHull;
    end
end

function bEnd = checkFullExt(startHull, endHull, path)
    global CellHulls CellTracks HashedCells
    bEnd = false;
    
    if ( CellHulls(endHull).time >= length(HashedCells) )
        bEnd = true;
        return
    end
end

function bsame = dblcheck(ext, tstext, tstcost)
    bsame = false;
    if ( length(ext) ~= length(tstext) )
        return;
    end
    
    for i=1:length(ext)
        if ( ~all(ext(i).path == tstext{i}) )
            return;
        end
        
        if ( ext(i).cost ~= tstcost(i) )
            return;
        end
    end
    
    bsame = true;
end

function leafHulls = getLeafHulls(rootTracks)
    global CellTracks CellHulls
    
    leafHulls = [];
    for i=1:length(rootTracks)
        subtreeTracks = getSubtreeTracks(rootTracks);
        for j=1:length(subtreeTracks)
            if ( ~isempty(CellTracks(subtreeTracks(j)).childrenTracks) )
                continue;
            end
            
            leafHulls = union(leafHulls, GetHullID(CellTracks(subtreeTracks(j)).endTime,subtreeTracks(j)));
        end
    end
    
    trackEnds = [CellHulls(leafHulls).time];
    [trackEnds srtidx] = sort(trackEnds);
    leafHulls = leafHulls(srtidx);
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

function bGoodExt = checkExtension(startHull, endHull, path)
    global CellTracks CellHulls
    
    bGoodExt = false;
    
    trackID = GetTrackID(endHull);
    bGoodTime = (CellTracks(trackID).startTime == CellHulls(endHull).time);
    if ( ~bGoodTime )
        return;
    end
    
    parentID = CellTracks(trackID).parentTrack;
    if ( ~isempty(parentID) )
        [costMatrix bPathHulls bNextHulls] = GetCostSubmatrix(path(end-1), 1:length(CellHulls));
        nxtHulls = find(bNextHulls);
        [dump minidx] = min(costMatrix);
        if ( nxtHulls(minidx) == endHull )
            return;
        end
    end
    
    bGoodExt = true;
end

function [paths pathCosts] = dijkstraSearch(startHull, costGraph, acceptFunc, maxExt)
    paths = {};
    pathCosts = [];
    
    bestCosts = sparse([],[],[],1,size(costGraph,1),round(0.01*size(costGraph,1)));
    bestPaths = cell(1,size(costGraph,1));
    
    bestPaths{startHull} = startHull;
    
    termHulls = [];
    
    trvList = [];
    trvHull = startHull;
    while ( true )
        
        nextHulls = find(costGraph(trvHull,:));
        nextPathCosts = costGraph(trvHull,nextHulls) + bestCosts(trvHull);
        
%         % Don't even bother putting paths that are higher cost in the list
%         bestChk = bestCosts(nextHulls);
%         bestChk(bestChk == 0) = Inf;
%         bKeepNext = (min([nextPathCosts;bestChk],[],1) == nextPathCosts);
%         nextHulls = nextHulls(bKeepNext);
%         nextPathCosts = nextPathCosts(bKeepNext);

        trvList = [trvList; nextPathCosts' trvHull*ones(length(nextHulls),1) nextHulls'];
        bestChk = full(bestCosts(trvList(:,3)));
        bestChk(bestChk == 0) = Inf;
        bKeepNext = (min([trvList(:,1)';bestChk],[],1) == trvList(:,1)');
        trvList = trvList(bKeepNext,:);
        
%         trvList = sortrows([trvList; nextPathCosts' trvHull*ones(length(nextHulls),1) nextHulls'],1);
        trvList = sortrows(trvList,1);
        
        while ( size(trvList,1) > 0 )
            if ( length(bestPaths{trvList(1,2)}) > maxExt )
                trvList = trvList(2:end,:);
                continue;
            end
            
            if ( (bestCosts(trvList(1,3))==0) )
                bestCosts(trvList(1,3)) = trvList(1,1);
                bestPaths{trvList(1,3)} = [bestPaths{trvList(1,2)} trvList(1,3)];
            elseif ( (bestCosts(trvList(1,3)) > trvList(1,1)) )
                error('This should never happen!');
            end

            % Is the next traversal a terminal node?
            if ( acceptFunc(startHull, trvList(1,3),[bestPaths{trvList(1,2)} trvList(1,3)]) )
                termHulls = union(termHulls,trvList(1,3));
                trvList = trvList(2:end,:);
                continue;
            end
            
            break;
        end
        
        if ( isempty(trvList) )
            break;
        end
        
        trvHull = trvList(1,3);
        trvList = trvList(2:end,:);
    end
    
    paths = cell(1,length(termHulls));
    pathCosts = zeros(1,length(termHulls));
    for i=1:length(termHulls)
        paths{i} = bestPaths{termHulls(i)};
        pathCosts(i) = bestCosts(termHulls(i));
    end
end
