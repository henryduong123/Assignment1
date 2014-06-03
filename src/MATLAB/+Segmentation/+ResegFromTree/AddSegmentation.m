function [addedHull costMatrix nextHulls] = AddSegmentation(prevHull, costMatrix, checkHulls, nextHulls, bAggressive)
    global CONSTANTS CellHulls HashedCells FluorData HaveFluor

    if ( ~exist('bAggressive','var') )
        bAggressive = 0;
    end
    
    addedHull = [];
    
    time = CellHulls(prevHull).time + 1;
    
    fileName = Helper.GetFullImagePath(time);
    img = Helper.LoadIntensityImage(fileName);
    
    guessPoint = [CellHulls(prevHull).centerOfMass(2) CellHulls(prevHull).centerOfMass(1)];
    
    newObj = Segmentation.FindNewSegmentation(img, guessPoint, 200, 1.0, CellHulls(prevHull).indexPixels, time);
    
    if ( isempty(newObj) )
        if ( ~bAggressive )
            return;
        end
        
        for tryAlpha = 0.95:(-0.05):0.5
            newObj = Segmentation.FindNewSegmentation(img, guessPoint, 200, tryAlpha, CellHulls(prevHull).indexPixels, time);
            if ( ~isempty(newObj) )
                break;
            end
        end
        
        if ( isempty(newObj) )
            return;
        end
    end
    
    newHull = Helper.MakeEmptyStruct(CellHulls);
    
    newHull.time = time;
    newHull.points = newObj.points;
    
    % Remove overlap with other hulls in the frame
    checkAllHulls = [HashedCells{time}.hullID];
    nextPix = vertcat(CellHulls(checkAllHulls).indexPixels);
    objPix = newObj.indPixels(~ismember(newObj.indPixels,nextPix));
    
    if ( length(objPix) < 20 )
        return;
    end
    
    newObj.indPixels = objPix;
    [r c] = ind2sub(CONSTANTS.imageSize, objPix);
    
    ch = Helper.ConvexHull(c,r);
    if ( isempty(ch) )
        newHull = [];
        return;
    end
    
    newHull.centerOfMass = mean([r c]);
    newHull.indexPixels = newObj.indPixels;
    
    newHull.points = [c(ch),r(ch)];
    
    % Check if newHull has a fluorescence marker
    if Helper.HaveFluor() && HaveFluor(time)
        greenInd = FluorData(time).greenInd;
        inter = intersect(newHull.indexPixels, greenInd);
        if (~isempty(inter))
            newHull.greenInd = 1;
        end
    end
    
    % Use temporary hull to verify cost (not on a track yet)
    chkIdx = find(checkHulls == prevHull);
    chkCosts = Segmentation.ResegFromTree.GetTestCosts(time-1, checkHulls, newHull);
    
    % [minCost minIdx] = min(chkCosts);
    % if ( minIdx ~= chkIdx )
    %     error('Not best incoming cost');
    % end
    
    % If will prefer something else over the added 
    prevEdgeCost = chkCosts(chkIdx);
    if ( prevEdgeCost > min(costMatrix(chkIdx,:)) )
        return;
    end
    
    addedHull = Hulls.SetHullEntries(0, newHull);
    
    nextHulls = [nextHulls addedHull];
    costMatrix = [costMatrix chkCosts];
end


