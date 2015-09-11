function connDist = UpdateConnDistance(updateHulls, hulls, hash)
    global ConnectedDist
    
    connDist = ConnectedDist;
    
    hullPerims = containers.Map('KeyType','uint32', 'ValueType','any');
    for i=1:length(updateHulls)
        if ( hulls(updateHulls(i)).deleted )
            continue;
        end
        
        connDist{updateHulls(i)} = [];
        t = hulls(updateHulls(i)).time;
        
        connDist = Tracker.UpdateDistances(updateHulls(i), t, t+1, hullPerims, connDist,hulls,hash);
        connDist = Tracker.UpdateDistances(updateHulls(i), t, t+2, hullPerims, connDist,hulls,hash);
        
        connDist = Tracker.UpdateDistances(updateHulls(i), t, t-1, hullPerims, connDist,hulls,hash);
        connDist = Tracker.UpdateDistances(updateHulls(i), t, t-2, hullPerims, connDist,hulls,hash);
    end
end