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
    global CellHulls HashedCells
    
    deleteCells = [];
    replaceCell = [];
    
    if ( isempty(mergeCells) )
        return;
    end
    
    t = CellHulls(mergeCells(1)).time;
    [mergeObj, deleteCells] = Segmentation.CreateMergedCell(mergeCells);
    
    if ( isempty(mergeObj) || isempty(deleteCells) )
        return;
    end
    
    nextMergeCells = getNextMergeCells(t, deleteCells);
    
    replaceCell = min(deleteCells);
    deleteCells = setdiff(deleteCells,replaceCell);
    
    mergeObj.userEdited = false;
    Hulls.SetHullEntries(replaceCell, mergeObj);
    
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

