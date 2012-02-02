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
    global CellFamilies CellTracks CellHulls CONSTANTS GraphEdits
    
    childHulls = arrayfun(@getRootHullID, CellFamilies, 'UniformOutput',0);
    childHulls = [childHulls{:}];
    
    costMatrix = GetCostMatrix();
    % Zero all secondary-edited mitosis edges so they cannot be patched
    % costMatrix(GraphEdits==2) = 0;
    
    % As stated elsewhere linear/binary indexing of large sparse cost
    % matrices is unsupported: see comments in GetCostMatrix()
    [r,c] = find(GraphEdits==2);
    for i=1:length(r)
        costMatrix(r(i),c(i)) = 0;
    end
    
    costMatrix = costMatrix(:,childHulls);
    parentHulls = find(any(costMatrix > 0,2));
    
    % Don't consider deleted hulls as parents
    bDeleted = [CellHulls(parentHulls).deleted];
    parentHulls = parentHulls(~bDeleted);
    
    costMatrix = costMatrix(parentHulls,:);
    
    [r,c,val] = find(costMatrix);
    [val,srtidx] = sort(val);
    r = r(srtidx);
    c = c(srtidx);
    
    bCheck = true(1,length(val));
    
    for idx=1:length(val)
        if ( ~bCheck(idx) )
            continue;
        end
        
        childTrack = GetTrackID(childHulls(c(idx)));
        parentTrack = GetTrackID(parentHulls(r(idx)));
        
        parentFuture = CellTracks(parentTrack).endTime - CellTracks(childTrack).startTime + 1;
        if ( parentFuture > CONSTANTS.minParentFuture )
            continue;
        end
        
        childLength = CellTracks(childTrack).endTime - CellTracks(childTrack).startTime + 1;
        if ( childLength <= parentFuture )
            continue;
        end
        
        if ( ~isempty(CellTracks(parentTrack).childrenTracks) )
            continue;
        end
        
        parentScore = GetTrackSegScore(parentTrack);
        childScore = GetTrackSegScore(childTrack);
        
        if ( parentScore < CONSTANTS.minTrackScore || childScore < CONSTANTS.minTrackScore )
            continue;
        end
        
        if ( CellTracks(childTrack).startTime <= CellTracks(parentTrack).endTime )
            RemoveFromTree(CellTracks(childTrack).startTime, parentTrack, 'no');
        end
        
        ChangeLabel(CellTracks(childTrack).startTime, childTrack, parentTrack);
        RehashCellTracks(parentTrack,CellTracks(parentTrack).startTime);
        
        bCheck((r == r(idx)) | (c == c(idx))) = 0;
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
