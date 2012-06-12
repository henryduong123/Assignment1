% ReassignTracks.m - Using cost submatrix appropriately reassign tracking
% over the given hulls.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     Copyright 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%     This file is part of LEVer - the tool for stem cell lineaging. See
%     https://pantherfile.uwm.edu/cohena/www/LEVer.html for details
% 
%     LEVer is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
%     LEVer is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
% 
%     You should have received a copy of the GNU General Public License
%     along with LEVer in file "gnu gpl v3.txt".  If not, see 
%     <http://www.gnu.org/licenses/>.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function changedHulls = ReassignTracks(t, costMatrix, extendHulls, affectedHulls, changedHulls, bPropForward)
    if ( ~exist('changedHulls','var') )
        changedHulls = [];
    end
    
    if ( ~exist('bPropForward','var') )
        bPropForward = 0;
    end
    
    if ( isempty(extendHulls) || isempty(affectedHulls) )
        return;
    end
    
    [minInCosts,bestIncoming] = min(costMatrix,[],1);
    [minOutCosts,bestOutgoing] = min(costMatrix,[],2);
    
    bestOutgoing  = bestOutgoing';
    bMatchedCol = false(size(bestIncoming));
    bMatched = (bestIncoming(bestOutgoing) == (1:length(bestOutgoing)));
    bMatchedCol(bestOutgoing(bMatched)) = 1;
    matchedIdx = find(bMatched);
    
    % Assign matched edges
	for i=1:length(matchedIdx)
        assignHull = affectedHulls(bestOutgoing(matchedIdx(i)));
        extHull = extendHulls(matchedIdx(i));
        
%         change = assignHullToTrack(t, assignHull, extHull, bPropForward);
        change = Tracker.AssignEdge(extHull, assignHull, bPropForward);
        changedHulls = [changedHulls change];
	end
    
    costMatrix(bMatched,:) = Inf;
    costMatrix(:,bMatchedCol) = Inf;
    
    [minCost minIdx] = min(costMatrix(:));
    
    % Patch up whatever other nurtureTracks we can
    while ( minCost ~= Inf )
        [r c] = ind2sub(size(costMatrix), minIdx);
        assignHull = affectedHulls(c);
        extHull = extendHulls(r);
        
%         change = assignHullToTrack(t, assignHull, extHull, bPropForward);
        change = Tracker.AssignEdge(extHull, assignHull, bPropForward);
        changedHulls = [changedHulls change];
        
        costMatrix(r,:) = Inf;
        costMatrix(:,c) = Inf;
        
        [minCost minIdx] = min(costMatrix(:));
    end
    
    changedHulls = unique(changedHulls);
end

function changedHulls = assignHullToTrack(t, hull, extHull, bUseChangeLabel)
    global HashedCells
    
    % Get track to which we will assign hull from extHulls
    track = Hulls.GetTrackID(extHull);
    
    oldHull = [];
    changedHulls = [];
    
	% Get old hull - track assignments
    oldHull = getOldHull(t, track);
    oldTrack = HashedCells{t}([HashedCells{t}.hullID] == hull).trackID;

    % Hull - track assignment is unchanged
    if ( oldHull == hull )
        return;
    end

    if ( bUseChangeLabel )
        exchangeTrackLabels(t, oldTrack, track);
        return;
    end
    
    if ( ~isempty(oldHull) )
        % Swap track assignments
        swapTracking(t, oldHull, hull, track, oldTrack);
        changedHulls = [oldHull hull];
    else
        % Add hull to track
        %TODO Fix func call
        [bDump,splitTrack] = Tracks.RemoveHullFromTrack(hull, oldTrack, 1);
        
        % Some RemoveHullFromTracke cases cause track to be changed
        track = Hulls.GetTrackID(extHull);
        oldHull = getOldHull(t, track);
        if ( ~isempty(oldHull) )
            if ( isempty(splitTrack) )
                error('Non-empty old cell ID without track split, cannot repair change');
            end
            
            reassignAndSwap(t, hull, splitTrack, oldHull, track);
            changedHulls = [oldHull hull];
        else
            Tracks.ExtendTrackWithHull(track, hull);
            changedHulls = hull;
        end
    end
end

% Special case: a split-track due to hull removal has caused us to want to
% assign hull to a track which now exists in this frame (oldHull), we first
% assign hull to splitTrack, then swap tracking in this frame.
function reassignAndSwap(t, hull, splitTrack, oldHull, track)
    Tracks.ExtendTrackWithHull(splitTrack, hull);
    swapTracking(t, oldHull, hull, track, splitTrack);
end

function oldHull = getOldHull(t, track)
    global HashedCells
    
    oldHull = [];
    
    oldHullIdx = find([HashedCells{t}.trackID] == track,1,'first');
    if ( isempty(oldHullIdx) )
        return;
    end
    
    oldHull = HashedCells{t}(oldHullIdx).hullID;
end

% Currently hullA has trackA, hullB has trackB
% swap so that hullA gets trackB and hullB gets trackA
function swapTracking(t, hullA, hullB, trackA, trackB)
    global HashedCells CellTracks
    
    hashAIdx = ([HashedCells{t}.hullID] == hullA);
    hashBIdx = ([HashedCells{t}.hullID] == hullB);
    
    % Swap track IDs
    HashedCells{t}(hashAIdx).trackID = trackB;
    HashedCells{t}(hashBIdx).trackID = trackA;
    
    % Swap hulls in tracks
    hashTime = t - CellTracks(trackA).startTime + 1;
    CellTracks(trackA).hulls(hashTime) = hullB;
    
    hashTime = t - CellTracks(trackB).startTime + 1;
    CellTracks(trackB).hulls(hashTime) = hullA;
end

function exchangeTrackLabels(t, oldTrack, track)
    global CellTracks CellFamilies
    
    Tracks.RehashCellTracks(track, CellTracks(track).startTime);
    Tracks.RehashCellTracks(oldTrack, CellTracks(oldTrack).startTime);
    
    if ( CellTracks(track).endTime >= t )
        %TODO fix func call
        Families.RemoveFromTreePrune(t, track, 'no');
    end
    
    if ( CellTracks(oldTrack).startTime < t )
        %TODO fix func call
        newFamID = Families.RemoveFromTreePrune(t, oldTrack, 'no');
        removeIfEmptyTrack(oldTrack);
        
        oldTrack = CellFamilies(newFamID).rootTrackID;
    end
    
    Tracks.ChangeTrackID(t, oldTrack, track);%TODO fix func call
end

function removeIfEmptyTrack(track)
    global CellTracks
    
    Tracks.RehashCellTracks(track);
    if ( ~isempty(CellTracks(track).hulls) )
        return;
    end
    
    childTracks = CellTracks(track).childrenTracks;
    for i=1:length(childTracks)
       %TODO fix func call
       Families.RemoveFromTreePrune(CellTracks(childTracks(i)).startTime, childTracks(i), 'no');
    end

    Families.RemoveTrackFromFamily(track);
    Tracks.ClearTrack(track);
end