%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     This file is part of LEVer.exe
%     (C) 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function trackIDs = TrackSplitHulls(newHulls, forceTracks, COM)
    global CellHulls HashedCells
    
    trackIDs = GetTrackID(newHulls);
    t = CellHulls(newHulls(1)).time;
    
    % Add new hulls to edited segmentations lists
    AddSegmentationEdit(newHulls, newHulls);
    
    [costMatrix, extendHulls, affectedHulls] = TrackThroughSplit(t, newHulls, COM);
    
    if ( isempty(costMatrix) )
        return;
    end
    
    changedHulls = ReassignTracks(t, costMatrix, extendHulls, affectedHulls, newHulls);
    
    if ( t+1 <= length(HashedCells) )
        nextHulls = [HashedCells{t+1}.hullID];
        UpdateTrackingCosts(t, changedHulls, nextHulls);
    end
    
    % All chnaged hulls get added (this may include track changes)
    AddSegmentationEdit([],changedHulls);
    
    trackIDs = [HashedCells{t}(ismember([HashedCells{t}.hullID],newHulls)).trackID];
end
