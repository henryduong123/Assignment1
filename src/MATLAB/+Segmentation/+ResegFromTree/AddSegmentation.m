function [addedHull costMatrix nextHulls] = AddSegmentation(prevHull, costMatrix, checkHulls, nextHulls, bAggressive)
    global CONSTANTS CellHulls HashedCells

    if ( ~exist('bAggressive','var') )
        bAggressive = 0;
    end
    
    addedHull = [];
    
    time = CellHulls(prevHull).time + 1;
    
    chanImSet = Helper.LoadIntensityImageSet(time);
    
    guessPoint = Helper.SwapXY_RC(CellHulls(prevHull).centerOfMass);
    chkHull = Segmentation.FindNewSegmentation(chanImSet, guessPoint, 200, bAggressive, CellHulls(prevHull).indexPixels, time);
    if ( isempty(chkHull) )
        return;
    end
    
    % Remove overlap with other hulls in the frame
    checkAllHulls = [HashedCells{time}.hullID];
    nextPix = vertcat(CellHulls(checkAllHulls).indexPixels);
    chkPix = chkHull.indexPixels(~ismember(chkHull.indexPixels,nextPix));
    
    if ( length(chkPix) < 20 )
        return;
    end
    
    newHull = Hulls.CreateHull(Metadata.GetDimensions('rc'), chkPix, time, false, chkHull.tag);
    
    % Use temporary hull to verify cost (not on a track yet)
    chkIdx = find(checkHulls == prevHull);
    chkCosts = Segmentation.ResegFromTree.GetTestCosts(time-1, checkHulls, newHull);
    
    % If will prefer something else over the added
    prevEdgeCost = chkCosts(chkIdx);
    if ( prevEdgeCost > min(costMatrix(chkIdx,:)) )
        return;
    end
    
    addedHull = Hulls.SetCellHullEntries(0, newHull);
    Editor.LogEdit('Add', [], addedHull, false);
    
    nextHulls = [nextHulls addedHull];
    costMatrix = [costMatrix chkCosts];
end


