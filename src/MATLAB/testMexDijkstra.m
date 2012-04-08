function testMexDijkstra()
    global CellHulls
    
    clear mex
    
    tic;
    costMatrix = GetCostMatrix();
    mexDijkstra('initGraph', costMatrix);
    
    maxFrameExt = 19;
    
    Progressbar(0);
    for i=1:length(CellHulls)
%         [pathExt pathCost] = dijkstraSearch(i, costMatrix, @checkExtension, maxFrameExt);
        [testPaths testCosts] = mexDijkstra('checkExtension', i, maxFrameExt+1);
        
%         [pathCost srtidx] = sort(pathCost);
%         pathExt = pathExt(srtidx);
%         
%         [testCosts srtidx] = sort(testCosts);
%         testPaths = testPaths(srtidx);
%         
%         if ( length(pathExt) ~= length(testPaths) )
%             error(['Unequal paths at i=' num2str(i) ' (lengths mismatched)']);
%         end
%         
%         for j=1:length(pathExt)
%             if ( testCosts(j) ~= pathCost(j) )
%                 error(['Unequal paths at i=' num2str(i) ' (' num2str(j) '-th cost mismatced)']);
%             end
%         end
%         
%         for j=1:length(pathExt)
%             if ( testPaths{j}(end) ~= pathExt{j}(end) )
%                 error(['Unequal paths at i=' num2str(i) ' (' num2str(j) '-th endHull mismatced)']);
%             end
%         end
        
        Progressbar(i / length(CellHulls));
    end
    
    toc
    
    disp('SWEETNESS!');
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
        nzParent = CellTracks(parentID).hulls(find(CellTracks(parentID).hulls,1,'last'));
        [costMatrix bPathHulls bNextHulls] = GetCostSubmatrix(nzParent, 1:length(CellHulls));
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