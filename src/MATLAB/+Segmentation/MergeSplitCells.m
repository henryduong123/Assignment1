% [deleteCells replaceCell] = MergeSplitCells(mergeCells)
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

function [deleteCells replaceCell] = MergeSplitCells(mergeCells)
    global CellHulls CellFeatures HashedCells
    
    deleteCells = [];
    replaceCell = [];
    
    if ( isempty(mergeCells) )
        return;
    end
    
    t = CellHulls(mergeCells(1)).time;
    [mergeObj, mergeFeat, deleteCells] = Segmentation.CreateMergedCell(mergeCells);
    
    if ( isempty(mergeObj) || isempty(deleteCells) )
        return;
    end
    
    nextMergeCells = getNextMergeCells(t, deleteCells);
    
    replaceCell = min(deleteCells);
    deleteCells = setdiff(deleteCells,replaceCell);
    
    mergeObj.userEdited = 0;
    Hulls.SetHullEntries(replaceCell, mergeObj, mergeFeat);
    
    for i=1:length(deleteCells)
        Hulls.RemoveHull(deleteCells(i));
    end
    
    [costMatrix, extendHulls, affectedHulls] = Tracker.TrackThroughMerge(t, replaceCell);
    if ( isempty(costMatrix) )
        return;
    end
    
    changedHulls = Tracker.ReassignTracks(costMatrix, extendHulls, affectedHulls, replaceCell);
    
    t = propagateMerge(replaceCell, changedHulls, nextMergeCells);

    if ( t < length(HashedCells) )
        checkHulls = [HashedCells{t}.hullID];
        nextHulls = [HashedCells{t+1}.hullID];
        
        [costMatrix bExtendHulls bAffectedHulls] = Tracker.GetCostSubmatrix(checkHulls, nextHulls);
        extendHulls = checkHulls(bExtendHulls);
        affectedHulls = nextHulls(bAffectedHulls);
        
        Tracker.ReassignTracks(costMatrix, extendHulls, affectedHulls, []);
    end
end

function tLast = propagateMerge(mergedHull, trackHulls, nextMergeCells)
    global CellHulls HashedCells

    tStart = CellHulls(mergedHull).time;
    tEnd = length(HashedCells)-1;
    
    propHulls = getPropagationCells(tStart+1, nextMergeCells);
    
    UI.Progressbar(0);
    
    idx = 1;
    tLast = tStart;
    for t=tStart:tEnd
        tLast = t;
        
        UI.Progressbar((t-tStart) / (tEnd-tStart));
        
        if ( isempty(mergedHull) )
            UI.Progressbar(1);
            return;
        end
        
        checkHulls = [HashedCells{t}.hullID];
        nextHulls = [HashedCells{t+1}.hullID];

        Tracker.UpdateTrackingCosts(t, trackHulls, nextHulls);
        
        [checkHulls,nextHulls] = Tracker.CheckGraphEdits(1, checkHulls, nextHulls);
        
        [costMatrix, bExtendHulls, bAffectedHulls] = Tracker.GetCostSubmatrix(checkHulls, nextHulls);
        extendHulls = checkHulls(bExtendHulls);
        affectedHulls = nextHulls(bAffectedHulls);
        
        bMhIdx = (extendHulls == mergedHull);
        [mincost,mergeIdx] = min(costMatrix(bMhIdx,:));
        
        if ( isempty(mincost) || isinf(mincost) )
            UI.Progressbar(1);
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
        [costMatrix bExtendHulls bAffectedHulls] = Tracker.GetCostSubmatrix(checkHulls, nextHulls);
        extendHulls = checkHulls(bExtendHulls);
        affectedHulls = nextHulls(bAffectedHulls);

        trackHulls = Tracker.ReassignTracks(costMatrix, extendHulls, affectedHulls, mergedHull);
    end
    
    UI.Progressbar(1);
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

function propHulls = getPropagationCells(t, mergeCells)
    global CellTracks
    
    propHulls = cell(length(mergeCells),1);
    trackIDs = [];
    for i=1:length(mergeCells)
        trackIDs = [trackIDs Hulls.GetTrackID(mergeCells(i))];
    end
    if (length(trackIDs)~=length(mergeCells))
        error('trackID doesn''t exist');
    end
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
    
    [mergeObj, mergeFeat, deleteCells] = Segmentation.CreateMergedCell(nextMergeHulls);
    if ( isempty(mergeObj) || isempty(deleteCells) )
        return;
    end
    
    replaceIdx = min(nextMergeHulls);
    deleteCells = setdiff(nextMergeHulls, replaceIdx);
    
    Hulls.SetHullEntries(replaceIdx, mergeObj, mergeFeat);
    
    for i=1:length(deleteCells)
        Hulls.RemoveHull(deleteCells(i));
    end
    
    Tracker.TrackThroughMerge(t, replaceIdx);
end

