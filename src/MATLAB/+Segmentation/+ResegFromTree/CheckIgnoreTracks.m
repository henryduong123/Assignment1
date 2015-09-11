% Ignore edges on tracks that end with phenotype markings or are currently
% outside view limits
function [bIgnoreEdges, bLongEdges] = CheckIgnoreTracks(t, trackIDs, viewLims)
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
            
            if ( ~checkHullCOMLims(prevHullID, viewLims) )
                bIgnoreEdges(i) = true;
                continue;
            end
        end
        
        [phenotypes, phenoHullIDs] = Tracks.GetAllTrackPhenotypes(curTrackID);
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

function bInLims = checkHullCOMLims(hullID, viewLims)
    global CONSTANTS CellHulls
    
    if ( isempty(hullID) || hullID == 0 )
        bInLims = false;
        return;
    end
    
    lenDims = viewLims(:,2) - viewLims(:,1);
    padScale = 0.05;
    
    imSize = CONSTANTS.imageSize;
    imSize([1 2]) = imSize([2 1]);
    
    bNotEdgeMin = (viewLims(:,1) >= 1+5);
    bNotEdgeMax = (viewLims(:,2) <= (imSize-5).');
    
    padInMin = bNotEdgeMin.*padScale.*lenDims;
    padInMax = bNotEdgeMax.*padScale.*lenDims;
    
    hullCOM = CellHulls(hullID).centerOfMass.';
    hullCOM([1 2]) = hullCOM([2 1]);
    
    bInDim = ((hullCOM > viewLims(:,1)+padInMin) & (hullCOM < viewLims(:,2)-padInMax));
    
    bInLims = all(bInDim);
end

