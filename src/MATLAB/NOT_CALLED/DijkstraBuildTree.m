function DijkstraBuildTree(rootTracks, stopTracks)
    global CellTracks CellHulls HashedCells
    
    startHulls = [];
    for i=1:length(rootTracks)
        startHulls = [startHulls Hulls.GetHullID(CellTracks(rootTracks(i)).startTime, rootTracks(i))];
    end
    
    if ( ~exist('stopTracks','var') )
        stopHulls = [HashedCells{end}.hullID];
    else
        for i=1:length(stopTracks)
            stopHulls = [stopHulls Hulls.GetHullID(CellTracks(stopTracks(i)).endTime, stopTracks(i))];
        end
    end
    
    paths = dijkstraPaths(startHulls, stopHulls);
    
    costs = [];
    startidx = [];
    pathidx = [];
    termhull = [];
    for i=1:length(paths)
        costs = [costs [paths{i}.cost]];
        startidx = [startidx i*ones(1,length(paths{i}))];
        for j=1:length(paths{i})
            pathidx = [pathidx j];
            termhull = [termhull paths{i}(j).path(end)];
        end
    end
    
    [costs srtidx] = sort(costs);
    startidx = startidx(srtidx);
    pathidx = pathidx(srtidx);
    termhull = termhull(srtidx);
    
    treePaths = {};
    treeTerm = [];
    splitTimes = [];
    parentTracks = [];
    tracks = [];
    
    for i=1:length(costs)
        isectidx = zeros(1,length(treePaths));
        for j=1:length(treePaths)
            [isect ia ib] = intersect(treePaths{j},paths{startidx(i)}(pathidx(i)).path);
            if ( ~isempty(ib) )
                isectidx(j) = max(ib);
            end
        end
        [maxisect parentidx] = max(isectidx);
        
        if ( any(treeTerm == termhull(i)) )
            continue;
        end
        
        treeTerm = [treeTerm termhull(i)];
        parentTracks = [parentTracks 0];
        splitTimes = [splitTimes 0];
        if ( isempty(maxisect) || maxisect == 0 )
            treePaths = [treePaths paths{startidx(i)}(pathidx(i)).path];
        else
            treePaths = [treePaths paths{startidx(i)}(pathidx(i)).path(maxisect+1:end)];
            splitTimes(end) = CellHulls(paths{startidx(i)}(pathidx(i)).path(maxisect)).time;
        end
        newTrackID = buildTrack(treePaths{end});
        tracks = [tracks newTrackID];
        
        if ( maxisect ~= 0 )
            parentTracks(end) = tracks(parentidx);
        end
    end
    
    [splitTimes srtidx] = sort(splitTimes,2,'descend');
    parentTracks = parentTracks(srtidx);
    tracks = tracks(srtidx);
    
    for i=1:length(splitTimes)
        if ( splitTimes(i) == 0 )
            break;
        end
        
        Tracks.ChangeTrackParent(parentTracks(i),CellTracks(tracks(i)).startTime,tracks(i));
    end
end

function newTrackID = buildTrack(path)
    global CellHulls CellTracks
    
    startTime = CellHulls(path(1)).time;
    startTrack = Tracks.GetTrackID(path(1));
    
    if ( CellTracks(startTrack).startTime ~= startTime )
        %TODO fix func call
        Families.RemoveFromTree(startTime, startTrack, 'yes');
    end
    
    for t=1:length(path)-1
        Tracker.AssignEdge(path(t),path(t+1),0);
    end
    
    newTrackID = Tracks.GetTrackID(path(1));
end

function paths = dijkstraPaths(rootHulls, stopHulls)
    global CellHulls
    
    tStart = min([CellHulls(rootHulls).time]);
    tEnd = max([CellHulls(stopHulls).time]);
    
    allPaths = cell(1,length(rootHulls));
    pathHulls = cell(1,length(rootHulls));
    
    paths = cell(1,length(rootHulls));
    
    for i=1:length(rootHulls)
        pathHulls{i} = rootHulls(i);
        allPaths{i} = struct('path',{rootHulls(i)}, 'cost',{0});
    end
    
    UI.Progressbar(0);
    for t=tStart:tEnd-1
        for i=1:length(rootHulls)
            if ( isempty(pathHulls{i}) )
                continue;
            end
            
            [costMatrix bPathHulls bNextHulls] = Tracker.GetCostSubmatrix(pathHulls{i}, 1:length(CellHulls));
            
            if ( isempty(costMatrix) )
                continue;
            end
            
            allPaths{i} = allPaths{i}(bPathHulls);
            nextHulls = find(bNextHulls);
            
            bDeleted = [CellHulls(nextHulls).deleted];
            nextHulls = nextHulls(~bDeleted);
            costMatrix = costMatrix(:,~bDeleted);
            
            costMatrix = costMatrix + ([allPaths{i}.cost]')*ones(1,length(nextHulls));
            
            [minInCosts bestIncoming] = min(costMatrix,[],1);
            %[dumpIn keepIdx repIdx] = unique(bestIncoming);
            
            allPaths{i} = allPaths{i}(bestIncoming);
            
            for j=1:length(allPaths{i})
                allPaths{i}(j).path = [allPaths{i}(j).path nextHulls(j)];
                allPaths{i}(j).cost = minInCosts(j);
            end
            
            bStopHull = ismember(nextHulls,stopHulls);
            paths{i} = [paths{i} allPaths{i}(bStopHull)];
            
            allPaths{i} = allPaths{i}(~bStopHull);
            pathHulls{i} = nextHulls;
        end
        UI.Progressbar((t - tStart)/(tEnd - tStart));
    end
    UI.Progressbar(1);
end