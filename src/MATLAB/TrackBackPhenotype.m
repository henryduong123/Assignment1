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

function TrackBackPhenotype(leafHulls, keyframeHulls)
    global CellHulls HashedCells
    
    
    goodTracks = struct('familyID',[], 'parentTrack',[], 'siblingTrack',[], 'childrenTracks',[], 'hulls',[], ...
                        'startTime',[], 'endTime',[], 'color',[]);
    
    leafHulls = unique(leafHulls);
    
    startHulls = union(leafHulls, keyframeHulls);
    
	for i=1:length(startHulls)
        goodTracks(i).hulls = startHulls(i);
        goodTracks(i).startTime = CellHulls(startHulls(i)).time;
        goodTracks(i).endTime = CellHulls(startHulls(i)).time;
    end
    
    tStart = max([CellHulls(startHulls).time]);
    
    bCurGood = ([CellHulls(startHulls).time] == tStart);
    trackHulls = startHulls(bCurGood);
    
    missedHulls = [];
    Progressbar(0);
    for t=tStart:-1:2
        if ( isempty(trackHulls) )
            break;
        end
        
        Progressbar((tStart - t + 1)/(tStart - 1));

        nextHulls = [HashedCells{t-1}.hullID];
        UpdateTrackingCosts(t, trackHulls, nextHulls);
        
        [trackHulls,nextHulls] = CheckGraphEdits(-1, trackHulls,nextHulls);
        
        maxOcclSkip = 1;
        if ( ~isempty(missedHulls) )
            missedHulls([CellHulls(missedHulls).time] > t+maxOcclSkip) = [];
            for occlSkip=1:maxOcclSkip
                if ( t+occlSkip > length(HashedCells) )
                    break;
                end
                
                curMissHulls = missedHulls([CellHulls(missedHulls).time] == t+occlSkip);
                if ( isempty(curMissHulls) )
                    continue;
                end

                UpdateTrackingCosts(t+occlSkip, curMissHulls, nextHulls);
                trackHulls = [trackHulls curMissHulls];
            end
        end
        
        [costMatrix,bNextHulls,bTrackedHulls] = GetCostSubmatrix(nextHulls, trackHulls);
        costMatrix = (costMatrix');
        
        trackedHulls = trackHulls(bTrackedHulls);
        nextHulls = nextHulls(bNextHulls);
        
        bAssign = assignBackTracks(t-1, costMatrix, trackedHulls, nextHulls, 0);
        
        missedHulls = trackHulls(~ismember(trackHulls, trackedHulls(any(bAssign,2))));
        trackHulls = nextHulls(any(bAssign,1));
        trackHulls = union(trackHulls, startHulls([CellHulls(startHulls).time] == t-1));
    end
    
    Progressbar(1);
end

function bAssign = assignBackTracks(t, costMatrix, trackedHulls, nextHulls, bPropForward)
    [minInCosts,bestIncoming] = min(costMatrix,[],1);
    [minOutCosts,bestOutgoing] = min(costMatrix,[],2);
    
    bAssign = false(size(costMatrix));
    
    if ( isempty(costMatrix) )
        return;
    end
    
    bestOutgoing  = bestOutgoing';
    bMatchedCol = false(size(bestIncoming));
    bMatched = (bestIncoming(bestOutgoing) == (1:length(bestOutgoing)));
    bMatchedCol(bestOutgoing(bMatched)) = 1;
    matchedIdx = find(bMatched);
    
    % Assign matched edges
	for i=1:length(matchedIdx)
        if ( minOutCosts(matchedIdx(i)) == Inf )
            continue;
        end
        
        assignHull = nextHulls(bestOutgoing(matchedIdx(i)));
        extHull = trackedHulls(matchedIdx(i));
        
%         [tracks, hash] = extendBackTrack(extHull, assignHull, tracks, hash);
        assignHullToTrack(t, assignHull, extHull, bPropForward);
        bAssign(matchedIdx(i), bestOutgoing(matchedIdx(i))) = 1;
    end
end

function changedHulls = assignHullToTrack(t, hull, extHull, bUseChangeLabel)
    global HashedCells
    
    % Get track to which we will assign hull from extHulls
    track = GetTrackID(extHull);
    
    oldHull = [];
    changedHulls = [];
    
	% Get old hull - track assignments
    bOldHull = [HashedCells{t}.trackID] == track;
    if ( any(bOldHull) )
        oldHull = HashedCells{t}(bOldHull).hullID;
    end
    
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
        RemoveHullFromTrack(hull, oldTrack, 1, -1);
        
        % Some RemoveHullFromTrack cases cause track to be changed
        track = GetTrackID(extHull);
        ExtendTrackWithHull(track, hull);
        changedHulls = hull;
    end
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
    
    RehashCellTracks(track, CellTracks(track).startTime);
    RehashCellTracks(oldTrack, CellTracks(oldTrack).startTime);
    
    if ( CellTracks(track).endTime >= t )
        RemoveFromTree(t, track, 'no');
    end
    
    if ( CellTracks(oldTrack).startTime < t )
        newFamID = RemoveFromTree(t, oldTrack, 'no');
        removeIfEmptyTrack(oldTrack);
        
        oldTrack = CellFamilies(newFamID).rootTrackID;
    end
    
    ChangeLabel(t, oldTrack, track);
end

function removeIfEmptyTrack(track)
    global CellTracks
    
    RehashCellTracks(track);
    if ( ~isempty(CellTracks(track).hulls) )
        return;
    end
    
    childTracks = CellTracks(track).childrenTracks;
    for i=1:length(childTracks)
        RemoveFromTree(CellTracks(childTracks(i)).startTime, childTracks(i), 'no');
    end

    RemoveTrackFromFamily(track);
    ClearTrack(track);
end

