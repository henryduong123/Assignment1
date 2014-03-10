function UpdateHullTracking(newHulls)
    global HashedCells CellHulls
    
    for i=1:length(newHulls)
        hullTime = CellHulls(newHulls(i)).time;
        
        if ( hullTime > 1 )
            lastHulls = [HashedCells{hullTime-1}.hullID];
            Tracker.UpdateTrackingCosts(hullTime-1, lastHulls, newHulls(i));
        end

        if ( hullTime < length(HashedCells) )
            nextHulls = [HashedCells{hullTime+1}.hullID];
            Tracker.UpdateTrackingCosts(hullTime, newHulls, newHulls(i));
        end
    end
end
