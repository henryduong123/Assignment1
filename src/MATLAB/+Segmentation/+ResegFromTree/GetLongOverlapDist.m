function ccDist = GetLongOverlapDist(fromHull, toHulls)
    global CONSTANTS CellHulls
    
    ccDist = Inf*ones(1,length(toHulls));
    
    if ( isempty(toHulls) )
        return;
    end
    
    t = CellHulls(fromHull).time;
    tNext = [CellHulls(toHulls).time];
    
    tDist = abs(tNext-t);
    bNeedCalc = (tDist > 2);
    preCalcIdx = find(~bNeedCalc);
    
    for i=1:length(preCalcIdx)
        ccDist(preCalcIdx(i)) = Tracker.GetConnectedDistance(fromHull, toHulls(preCalcIdx(i)));
    end
    
    if ( nnz(bNeedCalc) > 0 )
        hullPerims = containers.Map('KeyType','uint32', 'ValueType','any');
        ccDist(bNeedCalc) = Tracker.CalcHullConnectedDistances(fromHull, toHulls(bNeedCalc), hullPerims, CellHulls);
    end
    
    ccDist(ccDist > CONSTANTS.dMaxConnectComponent) = Inf;
end