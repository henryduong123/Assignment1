
function bCanExtend = CanExtendTrack(t, tracks)
    global CellHulls
    
    bCanExtend = true(length(tracks),1);
    
    for i=1:length(tracks)
        [phenotype phenoHullID] = Tracks.GetTrackPhenoypeTimes(tracks(i));
        if ( phenotype == 0 )
            continue;
        end
        
        phenoTime = CellHulls(phenoHullID).time;
        if ( t <= phenoTime )
            continue;
        end
        
        prevHullID = Helper.GetNearestTrackHull(tracks(i), t-1, -1);
        if ( prevHullID ~= phenoHullID )
            continue;
        end
        
        bCanExtend(i) = false;
    end
end