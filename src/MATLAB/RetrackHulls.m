function RetrackHulls(resegHulls)
    global CellHulls HashedCells CellTracks CellFamilies;
    
    clearTrackData();
    
    for t=1:(length(HashedCells)-1)
        checkHulls = [HashedCells{t}.hullID];
        nextHulls = [HashedCells{t+1}.hullID];
        
        
    end
end

function clearTrackData()
    global CellTracks HashedCells CellFamilies
    
    
end