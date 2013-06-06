function dist = GetLongOverlapDist(fromHull, toHulls)
    global CellHulls CONSTANTS
    
    dist = Inf*ones(1,length(toHulls));
    
    if ( isempty(toHulls) )
        return;
    end
    
    t = CellHulls(fromHull).time;
    tNext = CellHulls(toHulls(1)).time;
    
    if ( (tNext - t) <= 2 )
        for i=1:length(toHulls)
            dist(i) = Tracker.GetConnectedDistance(fromHull, toHulls(i));
        end
        return;
    end
    
    tDist = abs(tNext-t);
    
    comDistSq = sum((ones(length(toHulls),1)*CellHulls(fromHull).centerOfMass - vertcat(CellHulls(toHulls).centerOfMass)).^2, 2);
    
    checkIdx = find(comDistSq <= ((tDist*CONSTANTS.dMaxCenterOfMass)^2));
    
    [r c] = ind2sub(CONSTANTS.imageSize, CellHulls(fromHull).indexPixels);
    for i=1:length(checkIdx)
        [rNext cNext] = ind2sub(CONSTANTS.imageSize, CellHulls(toHulls(checkIdx(i))).indexPixels);
        
        isect = intersect(CellHulls(fromHull).indexPixels, CellHulls(toHulls(checkIdx(i))).indexPixels);
        if ( ~isempty(isect) )
            isectDist = 1 - (length(isect) / min(length(CellHulls(fromHull).indexPixels), length(CellHulls(toHulls(checkIdx(i))).indexPixels)));
            dist(checkIdx(i)) = isectDist;
            continue;
        end
        
        ccMinDistSq = Inf;
        for k=1:length(r)
            ccDistSq = (rNext-r(k)).^2 + (cNext-c(k)).^2;
            ccRowMin = min(ccDistSq);
            if ( ccRowMin < ccMinDistSq )
                ccMinDistSq = ccRowMin;
            end
            
            if ( ccRowMin < 1 )
                break;
            end
        end
        
        if ( ccMinDistSq > (CONSTANTS.dMaxConnectComponent^2) )
            continue;
        end
        
        dist(checkIdx(i)) = sqrt(ccMinDistSq);
    end
end