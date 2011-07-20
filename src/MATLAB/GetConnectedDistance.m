function dist = GetConnectedDistance(hull, nextHull)
    global CellHulls, ConnectedDist
    
    dist = Inf;
    
    firstHull = hull;
    secondHull = nextHull;
    if ( CellHulls(hull).time > CellHulls(nextHull).time )
        firstHull = nextHull;
        secondHull = hull;
    end
    
    ccIdx = find(ConnectedDist{firstHull}(:,1) == secondHull);
    if ( isempty(ccIdx) )
        return;
    end
    
    dist = 1000*ConnectedDist{firstHull}(ccIdx,2);
end