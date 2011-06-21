%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     This file is part of LEVer.exe
%     (C) 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [costMatrix extendHulls affectedHulls] = TrackThroughMerge(t, mergeHull)
    global CONSTANTS CellHulls HashedCells
    
    costMatrix = [];
    extendHulls = [];
    affectedHulls = [];
    
    % Update incoming and outgoing connected-component distance for new hulls
    BuildConnectedDistance(mergeHull, 1);
    
    if ( t <= 1 )
        return;
    end
    
    curHulls = [HashedCells{t}.hullID];
    lastHulls = [HashedCells{t-1}.hullID];
    
    distSq = sum((vertcat(CellHulls(lastHulls).centerOfMass) - ones(length(lastHulls),1)*CellHulls(mergeHull).centerOfMass).^2, 2);
    
    bTrackHull = distSq < ((2*CONSTANTS.dMaxCenterOfMass)^2);
    trackHulls = lastHulls(bTrackHull);
    
    if ( isempty(trackHulls) )
        return;
    end

    UpdateTrackingCosts(t-1, trackHulls, mergeHull);
    
    [costMatrix, bOutTracked, bInTracked] = GetCostSubmatrix(trackHulls, curHulls);
    extendHulls = trackHulls(bOutTracked);
    affectedHulls = curHulls(bInTracked);
end