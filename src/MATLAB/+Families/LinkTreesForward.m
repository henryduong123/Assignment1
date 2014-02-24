function [assignedExtensions findTime extTime] = LinkTreesForward(rootTracks, stopTime)
    global CellHulls CellTracks HashedCells Costs

    assignedExtensions = 0;
    foundExtensions = 0;
    
    findTime = 0;
    extTime = 0;
    
    if ( ~exist('stopTime','var') )
        stopTime = length(HashedCells);
    end
    
    rootTracks = unique(getRootTracks(rootTracks));
    
    % Initialize mex routine with current cost-graph
    costMatrix = Tracker.GetCostMatrix();
    mexDijkstra('initGraph', costMatrix);
    
    % Get all initial leaves for the root tracks
    leafHulls = getLeafHulls(rootTracks);
    tStart = CellHulls(leafHulls(1)).time;
    tEnd = length(HashedCells);
    
    maxFrameExt = 10;
    
% 	extGraph = sparse([],[],[], size(Costs,1),size(Costs,1), round(0.01*size(Costs,1)));
% 	extEnds = sparse([],[],[], size(Costs,1),size(Costs,1), round(0.01*size(Costs,1)));

    hull2Track = cellfun(@(x)(cell2mat(struct2cell(x'))), HashedCells, 'UniformOutput',0);
    hull2Track = [hull2Track{:}];
    cachedTracks = zeros(length(CellHulls),1);
    cachedTracks(hull2Track(1,:)) = hull2Track(2,:);
    
    bValidTermHulls = allValidTerminals();
    
    leafGraphHandle = Families.LinkTreesForward.GetFamilyLeafCosts(stopTime);
    
    extGraphSize = 0;
    extGraphR = zeros(2*nnz(Costs),1);
    extGraphC = zeros(2*nnz(Costs),1);
    extGraphCost = zeros(2*nnz(Costs),1);
    extGraphEnds = zeros(2*nnz(Costs),1);
    
    bCheckLeaves = false(1,length(CellHulls));
    
    chkFindTime = tic();
    UI.Progressbar(0);
    i = 1;
    
    checkExtHulls = leafHulls;
    bCheckLeaves(checkExtHulls) = true;
    while ( i <= length(checkExtHulls) )
        curCheckHull = checkExtHulls(i);
        
        if ( CellHulls(curCheckHull).time >= tEnd )
            i = i + 1;
            continue;
        end
        
        [pathExt pathCost] = mexDijkstra('checkExtension', curCheckHull, maxFrameExt);
        % [pathExt pathCost] = dijkstraSearch(checkExtHulls(i), costMatrix, @checkExtension, maxFrameExt);
        
        endHulls = zeros(1,length(pathExt));
        for j=1:length(pathExt)
            endHulls(j) = pathExt{j}(end);
        end
        
        extHulls = unique(endHulls);
%         extTracks = Hulls.GetTrackID(extHulls);
        extTracks = cachedTracks(extHulls);
        
        for j=1:length(extHulls)
%             nextLeaves = find(leafMatrix(extHulls(j),:));
%             nextLeaves = getLeafHulls(extTracks(j));
            [nextLeaves nextCosts] = mexGraph('edgesOut', leafGraphHandle, extHulls(j));
            
            if ( isempty(nextLeaves) )
                nextLeaves = extHulls(j);
                nextCosts = 0;
            end
            
            extIdx = find(endHulls == extHulls(j));
            for k=1:length(extIdx)
                for l = 1:length(nextLeaves)
                    trackCost = nextCosts(l);
                    
%                     if ( (nextLeaves(l) == extTracks(j)) )
%                         trackCost = 1;
%                     else
%                         trackCost = leafMatrix(extHulls(j),nextLeaves(l));
%                     end

                    extendCost = trackCost + pathCost(extIdx(k));
                    
                    extGraphSize = extGraphSize + 1;
                    
                    extGraphR(extGraphSize) = curCheckHull;
                    extGraphC(extGraphSize) = nextLeaves(l);
                    extGraphCost(extGraphSize) = extendCost;
                    extGraphEnds(extGraphSize) = pathExt{extIdx(k)}(end);
%                     extGraph(checkExtHulls(i),nextLeaves(l)) = extendCost;
%                     extEnds(checkExtHulls(i),nextLeaves(l)) = pathExt{extIdx(k)}(end);
                end
            end
            
            addLeaves = nextLeaves(~bCheckLeaves(nextLeaves));
            
            checkExtHulls = [checkExtHulls addLeaves];
            bCheckLeaves(addLeaves) = true;
        end
        
        UI.Progressbar((i/length(checkExtHulls))/2);
        
        i = i + 1;
    end
    
    findTime = toc(chkFindTime);
    
    extGraph = sparse(extGraphR(1:extGraphSize),extGraphC(1:extGraphSize),extGraphCost(1:extGraphSize), size(Costs,1),size(Costs,1));
	extEnds = sparse(extGraphR(1:extGraphSize),extGraphC(1:extGraphSize),extGraphEnds(1:extGraphSize), size(Costs,1),size(Costs,1));
    
    
    chkExtendTime = tic();
    
    foundExtensions = nnz(extGraph);
    assignedExtensions = 0;
    
    leafTimes = [CellHulls(leafHulls).time];
    [dump srtidx] = sort(leafTimes);
    
    mexDijkstra('initGraph', extGraph);
    
    bTermHulls = ([CellHulls.time] >= stopTime);
    
    leafHulls = leafHulls(srtidx);
    for i=1:length(leafHulls)
        % Only check best-to-end for now
        [endpaths endcosts] = mexDijkstra('matlabExtend', leafHulls(i), Inf, @(startHull,endHull)(bTermHulls(endHull)));
        
        if ( isempty(endcosts) )
            continue;
        end
        
        [mincost minidx] = min(endcosts);
        for j=(length(endpaths{minidx})-1):-1:1
            startHull = endpaths{minidx}(j);
            finalHull = endpaths{minidx}(j+1);
            linkupHull = extEnds(startHull,finalHull);
            
            Tracker.AssignEdge(startHull, linkupHull);
            
            mexDijkstra('removeEdges', [], finalHull);
            mexDijkstra('removeEdges', startHull, []);
            
            [nextVerts nextCosts] = mexGraph('edgesOut', leafGraphHandle, linkupHull);
            [idxStart,idxEnds] = find(extEnds(:,nextVerts) == linkupHull);
            mexDijkstra('removeEdges', idxStart, nextVerts(idxEnds));
        end
        
        assignedExtensions = assignedExtensions + length(endpaths{minidx}) - 1;
        
        UI.Progressbar(0.5 + ((i/length(leafHulls))/2));
    end
    
    UI.Progressbar(1);
    
    mexGraph('deleteGraph', leafGraphHandle);

    extTime = toc(chkExtendTime);
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
            
            endHull = Tracks.GetHullID(CellTracks(subtreeTracks(j)).endTime,subtreeTracks(j));
            if ( endHull == 0 )
                Tracks.RehashCellTracks(subtreeTracks(j));
                endHull = Tracks.GetHullID(CellTracks(subtreeTracks(j)).endTime,subtreeTracks(j));
            end
            
            leafHulls = [leafHulls, endHull];
        end
    end
    
    leafHulls = unique(leafHulls);
    
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

function bValidTermHulls = allValidTerminals()
    global CellFamilies CellTracks CellHulls GraphEdits
    
    costMatrix = Tracker.GetCostMatrix();
    
    bValidTermHulls = false(length(CellHulls),1);
    
    for i=1:length(CellFamilies)
        if ( isempty(CellFamilies(i).startTime) )
            continue;
        end
        
        if ( CellFamilies(i).bLocked )
            continue;
        end
        
        % 1st hull on root track of family is always valid
        rootHull = CellTracks(CellFamilies(i).rootTrackID).hulls(1);
        bValidTermHulls(rootHull) = 1;
        
        checkTracks = CellFamilies(i).tracks;
        
        for j=1:length(checkTracks)
            if ( isempty(CellTracks(checkTracks(j)).childrenTracks) )
                continue;
            end
            
            childTracks = CellTracks(checkTracks(j)).childrenTracks;
            
            parentHull = CellTracks(checkTracks(j)).hulls(end);
            childrenHulls = [CellTracks(childTracks(1)).hulls(1) CellTracks(childTracks(2)).hulls(1)];
            
            mitCosts = costMatrix(parentHull, childrenHulls);
            [worseEdge, worseIdx] = max(mitCosts);
            worseChild = childrenHulls(worseIdx);
            if ( any(GraphEdits(:,worseChild) > 0) )
                continue;
            end
            
            bValidTermHulls(worseChild) = 1;
        end
    end
end

function rootTracks = getRootTracks(tracks)
    global CellTracks CellFamilies
    
    rootTracks = [];
    for i=1:length(tracks)
        if ( isempty(CellTracks(tracks(i)).startTime) )
            continue;
        end
        
        familyID = CellTracks(tracks(i)).familyID;
        rootTracks = [rootTracks CellFamilies(familyID).rootTrackID];
    end
end
