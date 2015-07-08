% [deleteCells replaceCell] = MergeSplitCells(mergeCells, selectedTree)
% Attempt to merge cells that are oversegmented and propagate the merge forward in time.

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

function [deleteCells replaceCell] = MergeSplitCells(mergeCells, selectedTree)
    global CellFamilies CellHulls HashedCells
    
    deleteCells = [];
    replaceCell = [];
    
    if ( isempty(mergeCells) )
        return;
    end
    
    t = CellHulls(mergeCells(1)).time;
    bestEdge = getLockedMergeTrack(t, mergeCells, selectedTree);
    [mergeObj, deleteCells] = Segmentation.CreateMergedCell(mergeCells);
    
    if ( isempty(mergeObj) || isempty(deleteCells) )
        return;
    end
    
    nextMergeCells = getNextMergeCells(t, deleteCells);
    
    replaceCell = min(deleteCells);
    deleteCells = setdiff(deleteCells,replaceCell);
    
    mergeObj.userEdited = true;
    Hulls.SetHullEntries(replaceCell, mergeObj);
    Editor.LogEdit('Merge', deleteCells, replaceCell, true);
    
    for i=1:length(deleteCells)
        Hulls.RemoveHull(deleteCells(i));
    end
    
    [costMatrix, extendHulls, affectedHulls] = Tracker.TrackThroughMerge(t, replaceCell);
    if ( isempty(costMatrix) )
        return;
    end
    
    changedHulls = Tracker.ReassignTracks(costMatrix, extendHulls, affectedHulls, replaceCell);

    if ( t < length(HashedCells) )
        checkHulls = [HashedCells{t}.hullID];
        nextHulls = [HashedCells{t+1}.hullID];
        
        [costMatrix bExtendHulls bAffectedHulls] = Tracker.GetCostSubmatrix(checkHulls, nextHulls);
        extendHulls = checkHulls(bExtendHulls);
        affectedHulls = nextHulls(bAffectedHulls);
        
        if ( ~isempty(bestEdge) )
            bestEdge(1) = replaceCell;
            [costMatrix extendHulls affectedHulls] = enforceTrackEdges(bestEdge, costMatrix,extendHulls,affectedHulls);
        end
        
        Tracker.ReassignTracks(costMatrix, extendHulls, affectedHulls, []);
    end
end

function nextMergeCells = getNextMergeCells(t, mergeCells)
    global CellTracks
    
    nextMergeCells = [];
    trackIDs = Hulls.GetTrackID(mergeCells);
    for i=1:length(trackIDs)
        hash = (t+1) - CellTracks(trackIDs(i)).startTime + 1;
        if ( (hash > length(CellTracks(trackIDs(i)).hulls)) || (CellTracks(trackIDs(i)).hulls(hash) == 0) )
            continue;
        end
        
        nextMergeCells = [nextMergeCells CellTracks(trackIDs(i)).hulls(hash)];
    end
end

function [costMatrix extendHulls affectedHulls] = enforceTrackEdges(edges, costMatrix,extendHulls,affectedHulls)
    for i=1:size(edges,1)
        rIdx = find(extendHulls == edges(i,1));
        cIdx = find(affectedHulls == edges(i,2));
        
        if ( isempty(rIdx) )
            costMatrix = [costMatrix;Inf*ones(1,size(costMatrix,2))];
            extendHulls = [extendHulls edges(i,1)];
            rIdx = length(extendHulls);
        end
        
        if ( isempty(cIdx) )
            costMatrix = [costMatrix Inf*ones(size(costMatrix,1),1)];
            affectedHulls = [affectedHulls edges(i,2)];
            cIdx = length(affectedHulls);
        end
        
        costMatrix(rIdx,:) = Inf;
        costMatrix(:,cIdx) = Inf;
        costMatrix(rIdx,cIdx) = 1;
    end
end

function bestEdge = getLockedMergeTrack(t, mergeCells, selectedTree)
    global CellFamilies
    
    bestEdge = [];
    
    oldTrackIDs = Hulls.GetTrackID(mergeCells);
    if ( CellFamilies(selectedTree).bLocked > 0 )
        curFamTracks = oldTrackIDs(ismember(oldTrackIDs,CellFamilies(selectedTree).tracks));
        if ( ~isempty(curFamTracks) )
            bestEdge = getTrackEdge(t, curFamTracks(1));
            return;
        end
    end
end

function edge = getTrackEdge(t, trackID)
    edge = [];
    
    startHull = Tracks.GetHullID(t,trackID);
    endHull = Helper.GetNearestTrackHull(trackID,t+1,+1);

    if ( any([startHull endHull] == 0) )
        return;
    end
    
    edge = [startHull endHull];
end
