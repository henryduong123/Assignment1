% MergeSplitCells.m - Attempt to merge cells that are oversegmented and 
% propagate the merge forward in time.

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

function [deleteCells replaceCell] = MergeSplitCells(mergeCells)
    global Figures CellHulls CellFeatures HashedCells CellTracks SegmentationEdits CellFamilies
    
    replaceCell = [];
    
    t = Figures.time;
    [mergeObj, mergeFeat, deleteCells] = CreateMergedCell(mergeCells);
    
    if ( isempty(mergeObj) || isempty(deleteCells) )
        return;
    end
    
    nextMergeCells = getNextMergeCells(t, deleteCells);
    
    replaceCell = min(deleteCells);
    deleteCells = setdiff(deleteCells,replaceCell);
    
    for i=1:length(deleteCells)
        RemoveHull(deleteCells(i), 1);
    end
    
    CellHulls(replaceCell).points = mergeObj.points;
    CellHulls(replaceCell).indexPixels = mergeObj.indexPixels;
    CellHulls(replaceCell).imagePixels = mergeObj.imagePixels;
    CellHulls(replaceCell).centerOfMass = mergeObj.centerOfMass;
    CellHulls(replaceCell).deleted = 0;
    CellHulls(replaceCell).userEdited = 1;
    
    % Set features if valid
    if ( ~isempty(CellFeatures) )
        CellFeatures(replaceCell) = mergeFeat;
    end
    
    [costMatrix, extendHulls, affectedHulls] = TrackThroughMerge(t, replaceCell);
    if ( isempty(costMatrix) )
        return;
    end
    
    changedHulls = ReassignTracks(t, costMatrix, extendHulls, affectedHulls, replaceCell);
    
    t = propagateMerge(replaceCell, changedHulls, nextMergeCells);

    if ( t < length(HashedCells) )
        checkHulls = [HashedCells{t}.hullID];
        nextHulls = [HashedCells{t+1}.hullID];
        
        [costMatrix bExtendHulls bAffectedHulls] = GetCostSubmatrix(checkHulls, nextHulls);
        extendHulls = checkHulls(bExtendHulls);
        affectedHulls = nextHulls(bAffectedHulls);
        
        ReassignTracks(t+1, costMatrix, extendHulls, affectedHulls, [], 1);
    end
    
    SegmentationEdits.newHulls = [];
    SegmentationEdits.changedHulls = [];
    SegmentationEdits.maxEditedFrame = length(HashedCells);
    SegmentationEdits.editTime = [];
    
    UpdateSegmentationEditsMenu();
    ProcessNewborns(1:length(CellFamilies), SegmentationEdits.maxEditedFrame);
end

function tLast = propagateMerge(mergedHull, trackHulls, nextMergeCells)
    global CellHulls HashedCells

    tStart = CellHulls(mergedHull).time;
    tEnd = length(HashedCells)-1;
    
    propHulls = getPropagationCells(tStart+1, nextMergeCells);
    
    idx = 1;
    tLast = tStart;
    for t=tStart:tEnd
        tLast = t;
        
        if ( isempty(mergedHull) )
            return;
        end
        
        checkHulls = [HashedCells{t}.hullID];
        nextHulls = [HashedCells{t+1}.hullID];

        UpdateTrackingCosts(t, trackHulls, nextHulls);
        
        [checkHulls,nextHulls] = CheckGraphEdits(1, checkHulls, nextHulls);
        
        [costMatrix, bExtendHulls, bAffectedHulls] = GetCostSubmatrix(checkHulls, nextHulls);
        extendHulls = checkHulls(bExtendHulls);
        affectedHulls = nextHulls(bAffectedHulls);
        
        bMhIdx = (extendHulls == mergedHull);
        [mincost,mergeIdx] = min(costMatrix(bMhIdx,:));
        
        if ( isempty(mincost) || isinf(mincost) )
            return;
        end
        
        mergedHull = checkMergeHulls(t+1, costMatrix, extendHulls, affectedHulls, mergedHull, nextMergeCells);
        
        for i=1:length(propHulls)
            if ( isempty(propHulls{i}) || (length(propHulls{i}) < idx) )
                continue;
            end
            
            nextMergeCells = [nextMergeCells propHulls{i}(idx)];
        end
        idx = idx + 1;
        
        nextHulls = [HashedCells{t+1}.hullID];
        [costMatrix bExtendHulls bAffectedHulls] = GetCostSubmatrix(checkHulls, nextHulls);
        extendHulls = checkHulls(bExtendHulls);
        affectedHulls = nextHulls(bAffectedHulls);

        trackHulls = ReassignTracks(t+1, costMatrix, extendHulls, affectedHulls, mergedHull);
    end
end

function nextMergeCells = getNextMergeCells(t, mergeCells)
    global CellTracks
    
    nextMergeCells = [];
    trackIDs = GetTrackID(mergeCells, t);
    for i=1:length(trackIDs)
        hash = (t+1) - CellTracks(trackIDs(i)).startTime + 1;
        if ( (hash > length(CellTracks(trackIDs(i)).hulls)) || (CellTracks(trackIDs(i)).hulls(hash) == 0) )
            continue;
        end
        
        nextMergeCells = [nextMergeCells CellTracks(trackIDs(i)).hulls(hash)];
    end
end

function propHulls = getPropagationCells(t, mergeCells)
    global CellTracks
    
    propHulls = cell(length(mergeCells),1);
    trackIDs = GetTrackID(mergeCells, t);
    for i=1:length(trackIDs)
        hash = (t+1) - CellTracks(trackIDs(i)).startTime + 1;
        if ( (hash > length(CellTracks(trackIDs(i)).hulls)) || (CellTracks(trackIDs(i)).hulls(hash) == 0) )
            continue;
        end
        
        propHulls{i} = CellTracks(trackIDs(i)).hulls(hash:end);
        zIdx = find((propHulls{i} == 0), 1, 'first');
        if ( zIdx > 0 )
            propHulls{i} = propHulls{i}(1:(zIdx-1));
        end
    end
end

function replaceIdx = checkMergeHulls(t, costMatrix, checkHulls, nextHulls, mergedHull, deleteHulls)
    global CellHulls CellFeatures
    
    mergedIdx = find(checkHulls == mergedHull);
    bDeleteHulls = ismember(nextHulls, deleteHulls);
    [minIn,bestIn] = min(costMatrix,[],1);
    
    deleteHulls = nextHulls(bDeleteHulls);
    nextMergeHulls = deleteHulls(bestIn(bDeleteHulls) == mergedIdx);
    
    bAllowMerge = (~[CellHulls(nextMergeHulls).userEdited]);
    nextMergeHulls = nextMergeHulls(bAllowMerge);

    replaceIdx = [];
    
    if ( length(nextMergeHulls) <= 1 )
        return;
    end
    
    [mergeObj, mergeFeat, deleteCells] = CreateMergedCell(nextMergeHulls);
    if ( isempty(mergeObj) || isempty(deleteCells) )
        return;
    end
    
    replaceIdx = min(nextMergeHulls);
    deleteCells = setdiff(nextMergeHulls, replaceIdx);
    
    CellHulls(replaceIdx).indexPixels = mergeObj.indexPixels;
    CellHulls(replaceIdx).imagePixels = mergeObj.imagePixels;
    CellHulls(replaceIdx).points = mergeObj.points;
    CellHulls(replaceIdx).centerOfMass = mergeObj.centerOfMass;
    CellHulls(replaceIdx).deleted = 0;
    
    % Set features if valid
    if ( ~isempty(CellFeatures) )
        CellFeatures(replaceIdx) = mergeFeat;
    end
    
    for i=1:length(deleteCells)
        RemoveHull(deleteCells(i), 1);
    end
    
    TrackThroughMerge(t, replaceIdx);
end

