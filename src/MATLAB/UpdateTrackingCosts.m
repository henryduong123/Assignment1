%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     This file is part of LEVer.exe
%     (C) 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Update the tracking costs tracking from trackHulls to nextHulls
function UpdateTrackingCosts(t, trackHulls, nextHulls)
    global CellHulls HashedCells Costs
    
    if ( t+1 > length(HashedCells) )
        return;
    end
    
    trackToHulls = [HashedCells{t+1}.hullID];
    
    avoidHulls = setdiff(trackToHulls,nextHulls);
    [costMatrix fromHulls toHulls] = TrackingCosts(trackHulls, t, avoidHulls, CellHulls, HashedCells);
    
    % Update newly tracked costs
    [r c] = ndgrid(fromHulls, toHulls);
    costIdx = sub2ind(size(Costs), r, c);
    Costs(costIdx) = costMatrix;
end