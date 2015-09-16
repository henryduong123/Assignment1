function [newSegs costMatrix nextHulls] = SplitSegmentation(splitHull, numSplit, prevHulls, mitosisParents, costMatrix, checkHulls, nextHulls)
    global CellHulls

    newSegs = [];
    
    if ( numSplit == 1 )
        newSegs = splitHull;
        return;
    end
    
    newHulls = Segmentation.ResegFromTree.SplitDeterministic(CellHulls(splitHull), numSplit, prevHulls);
    if ( isempty(newHulls) )
        return;
    end
    
    for i=1:length(newHulls)
        newHulls(i).userEdited = false;
    end
    
    % TODO: fixup incoming graphedits
    
    % TODO: Deal with mitosis events, 
    % TODO: This definitely needs work
    t = max([CellHulls(checkHulls).time]);
    newCosts = Segmentation.ResegFromTree.GetTestCosts(t, checkHulls, newHulls);
    
    % Just set long edges to a uniformly high cost
    bLongEdge = ([CellHulls(checkHulls).time] < t);
    newCosts(bLongEdge,:) = 1e20;
    
    splitIdx = find(nextHulls == splitHull,1,'first');
    [bHadMitosis mitIdx] = ismember(prevHulls, mitosisParents);
    
    [bDump prevIdx] = ismember(prevHulls, checkHulls);
    
    bAssignHullIdx = false(1,length(newHulls));
    bAssignHullIdx(1) = 1;
    if ( any(bHadMitosis) )
        [bestMitCost bestMitIdx] = min(newCosts(prevIdx(bHadMitosis),:));
        
        newCosts(prevIdx(bHadMitosis),:) = Inf;
        newCosts(prevIdx(bHadMitosis),bestMitIdx) = 1;
        
        bAssignHullIdx(1) = 0;
        bAssignHullIdx(bestMitIdx) = 1;
    end
    
    % Force a hungarian assignment for splits
    assignIdx = assign.assignmentoptimal(newCosts(prevIdx,:));
    % TODO: This can fail in cases where all single previous hulls get too
    % far away from one of the split segmentations. Need to re-evaluate
    % split in such cases.
    for i=1:length(assignIdx)
        newCosts(prevIdx(i),:) = Inf;
        newCosts(prevIdx,assignIdx(i)) = Inf;
        
        newCosts(prevIdx(i),assignIdx(i)) = 3;
    end
    
    setHullIDs = zeros(1,length(newHulls));
    setHullIDs(bAssignHullIdx) = splitHull;
    % Just arbitrarily assign clone's hull for now
    newSegs = Hulls.SetHullEntries(setHullIDs, newHulls);
    Editor.LogEdit('Split', splitHull, newSegs, false);
    
    updateIdx = find(nextHulls == splitHull);
    
    costMatrix(:,updateIdx) = newCosts(:,bAssignHullIdx);
    costMatrix = [costMatrix newCosts(:,~bAssignHullIdx)];
    nextHulls = [nextHulls newSegs(~bAssignHullIdx)];
end