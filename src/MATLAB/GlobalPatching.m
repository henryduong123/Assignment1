% GlobalPatching.m - Patch together tracks which may not have matched
% during tracking, patching globally lowest cost first.

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

function GlobalPatching()
    global CellFamilies CellTracks CONSTANTS GraphEdits
    
    childHulls = arrayfun(@getRootHullID, CellFamilies, 'UniformOutput',0);
    childHulls = [childHulls{:}];
    
    costMatrix = GetCostMatrix();
    costMatrix(GraphEdits==2) = 0;
    
    costMatrix = costMatrix(:,childHulls);
    parentHulls = find(any(costMatrix > 0,2));
    
    costMatrix = costMatrix(parentHulls,:);
    
    while( nnz(costMatrix) > 0 )
        [r,c,val] = find(costMatrix);
        [dump,idx] = min(val);
        
        childTrack = GetTrackID(childHulls(c(idx)));
        parentTrack = GetTrackID(parentHulls(r(idx)));
        
        parentFuture = CellTracks(parentTrack).endTime - CellTracks(childTrack).startTime + 1;
        if ( parentFuture > CONSTANTS.minParentFuture )
            costMatrix(r(idx),c(idx)) = 0;
            continue;
        end
        
        childLength = CellTracks(childTrack).endTime - CellTracks(childTrack).startTime + 1;
        if ( childLength <= parentFuture )
            costMatrix(r(idx),c(idx)) = 0;
            continue;
        end
        
        if ( ~isempty(CellTracks(parentTrack).childrenTracks) )
            costMatrix(r(idx),c(idx)) = 0;
            continue;
        end
        
        if ( CellTracks(childTrack).startTime <= CellTracks(parentTrack).endTime )
            RemoveFromTree(CellTracks(childTrack).startTime, parentTrack, 'no');
        end
        
        ChangeLabel(CellTracks(childTrack).startTime, childTrack, parentTrack);
        RehashCellTracks(parentTrack,CellTracks(parentTrack).startTime);
        
        costMatrix(r(idx),:) = 0;
        costMatrix(:,c(idx)) = 0;
    end
end

function hullID = getRootHullID(family)
    global CellTracks
    
    if ( isempty(family.startTime) )
        hullID = [];
        return;
    end
    
    hullID = CellTracks(family.rootTrackID).hulls(1);
end