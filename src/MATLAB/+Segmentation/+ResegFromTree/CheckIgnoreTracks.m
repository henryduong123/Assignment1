% Ignore edges on tracks that end with phenotype markings or are currently
% outside view limits
function [bIgnoreEdges bLongEdges] = CheckIgnoreTracks(t, trackIDs, viewLims)
    global CellHulls
    
    bIgnoreEdges = false(length(trackIDs),1);
    bLongEdges = false(length(trackIDs),1);
    
    for i=1:length(trackIDs)
        curTrackID = trackIDs(i);
        
        prevHullID = Helper.GetNearestTrackHull(curTrackID, t-1, -1);
        if ( (prevHullID ~= 0) )
            if ( (t - CellHulls(prevHullID).time) > 5 )
                bLongEdges(i) = true;
            end
            
            if ( ~checkCOMLims(prevHullID, viewLims) )
                bIgnoreEdges(i) = true;
                continue;
            end
        end
        
        [phenotypes phenoHullIDs] = Tracks.GetAllTrackPhenotypes(curTrackID);
        if ( isempty(phenotypes) )
            continue;
        end
        
        phenoHullID = phenoHullIDs(end);
        phenoTime = CellHulls(phenoHullID).time;
        if ( t <= phenoTime )
            continue;
        end
        
        if ( prevHullID ~= phenoHullID )
            continue;
        end
        
        bIgnoreEdges(i) = true;
    end
end

function bInLims = checkCOMLims(hullID, viewLims)
    global CONSTANTS CellHulls
    
    if ( isempty(hullID) || hullID == 0 )
        bInLims = false;
        return;
    end
    
    lenX = viewLims(1,2)-viewLims(1,1);
    lenY = viewLims(2,2)-viewLims(2,1);
    
    padXLeft = 0;
    padXRight = 0;
    padYTop = 0;
    padYBottom = 0;
    
    padScale = 0.05;
    
    if ( viewLims(1,1) >= 6 )
        padXLeft = padScale*lenX;
    end
    
    if ( viewLims(1,2) <= (CONSTANTS.imageSize(2)-5) )
        padXRight = padScale*lenX;
    end
    
    if ( viewLims(2,1) >= 6 )
        padYTop = padScale*lenY;
    end
    
    if ( viewLims(2,2) <= (CONSTANTS.imageSize(1)-5) )
        padYBottom = padScale*lenY;
    end
    
    hull = CellHulls(hullID);
    bInX = ((hull.centerOfMass(2)>(viewLims(1,1)+padXLeft)) && (hull.centerOfMass(2)<(viewLims(1,2)-padXRight)));
    bInY = ((hull.centerOfMass(1)>(viewLims(2,1)+padYTop)) && (hull.centerOfMass(1)<(viewLims(2,2)-padYBottom)));
    
    bInLims = (bInX & bInY);
end

