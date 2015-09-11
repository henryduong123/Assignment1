function ccDist = CalcHullConnectedDistances(hullID, nextHullIDs, hullPerims, hulls)
    global CONSTANTS
    
    ccDist = Inf*ones(1,length(nextHullIDs));
    
    if ( isempty(nextHullIDs) )
        return;
    end
    
    t = hulls(hullID).time;
    tNext = vertcat(hulls(nextHullIDs).time);
    
    tDist = abs(tNext-t);
    comDistSq = sum((ones(length(nextHullIDs),1)*hulls(hullID).centerOfMass - vertcat(hulls(nextHullIDs).centerOfMass)).^2, 2);
    
    chkHullIdx = find(comDistSq <= (tDist*CONSTANTS.dMaxCenterOfMass).^2);
    checkHullIDs = nextHullIDs(chkHullIdx);
    
    if ( isempty(checkHullIDs) )
        return;
    end
    
    for i=1:length(checkHullIDs)
        chkDist = Helper.CalcConnectedDistance(hullID,checkHullIDs(i), CONSTANTS.imageSize, hullPerims, hulls);
        ccDist(chkHullIdx(i)) = chkDist;
    end
end
