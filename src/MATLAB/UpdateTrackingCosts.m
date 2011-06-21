%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     This file is part of LEVer.exe
%     (C) 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Update the tracking costs tracking from trackHulls to nextHulls
function UpdateTrackingCosts(t, trackHulls, nextHulls)
    global CellHulls HashedCells CellTracks Costs
    
    windowSize = 4;
    
    if ( isempty(nextHulls) )
        return;
    end
    
    tNext = CellHulls(nextHulls(1)).time;
    
    if ( isempty(tNext) || tNext > length(HashedCells) || tNext < 1 )
        return;
    end
    
    dir = 1;
    if ( tNext < t )
        dir = -1;
    end
%     trackHulls = checkEditedHistory(windowSize, dir, trackHulls);
    
    trackToHulls = [HashedCells{tNext}.hullID];
    
    avoidHulls = setdiff(trackToHulls,nextHulls);
    %[costMatrix fromHulls toHulls] = TrackingCosts(trackHulls, t, avoidHulls, CellHulls, HashedCells);
    [costMatrix fromHulls toHulls] = GetTrackingCosts(windowSize, t, tNext, trackHulls, avoidHulls, CellHulls, HashedCells, CellTracks);
    
    % Update newly tracked costs
    if ( dir > 0 )        
        [r c] = ndgrid(fromHulls, toHulls);
        costIdx = sub2ind(size(Costs), r, c);
        Costs(costIdx) = costMatrix;
    else
        [r c] = ndgrid(toHulls, fromHulls);
        costIdx = sub2ind(size(Costs), r, c);
        Costs(costIdx) = (costMatrix');
    end
end

% function trackHulls = checkEditedHistory(windowSize, dir, fromHulls)
%     global CellTracks GraphEdits
%     
%     for i=1:length(fromHulls)
%         
%     end
% end

