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

function bInLims = checkHullCOMLims(hullID, xyViewLims)
    global CONSTANTS CellHulls
    
    if ( isempty(hullID) || hullID == 0 )
        bInLims = false;
        return;
    end
    
    lenDims = xyViewLims(:,2) - xyViewLims(:,1);
    padScale = 0.05;
    
    imSize = Helper.SwapXY_RC(CONSTANTS.imageSize);
    
    bNotEdgeMin = (xyViewLims(:,1) >= 1+5);
    bNotEdgeMax = (xyViewLims(:,2) <= (imSize-5).');
    
    padInMin = bNotEdgeMin.*padScale.*lenDims;
    padInMax = bNotEdgeMax.*padScale.*lenDims;
    
    hullCOM = Helper.SwapXY_RC(CellHulls(hullID).centerOfMass).';
    
    bInDim = ((hullCOM > xyViewLims(:,1)+padInMin) & (hullCOM < xyViewLims(:,2)-padInMax));
    
    bInLims = all(bInDim);
end

