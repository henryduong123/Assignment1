% UpdateCachedCosts(fromHulls, toHulls)
% This must be run after a cost matrix or graph-edits change to keep cached
% costs up to date.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     Copyright 2016 Drexel University
%
%     This file is part of LEVer - the tool for stem cell lineaging. See
%     http://n2t.net/ark:/87918/d9rp4t for details
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


function UpdateCachedCosts(fromHulls, toHulls)
    global CellFamilies CellTracks CellHulls Costs GraphEdits CachedCostMatrix
    
    % Add any graphedited hulls to from/to list
    toHulls = union(toHulls, find(any(GraphEdits(fromHulls,:)~=0, 1)));
    fromHulls = union(fromHulls, find(any(GraphEdits(:,toHulls)~=0, 2)));
    
    % Don't mess with deleted edges
    fromHulls = fromHulls(~[CellHulls(fromHulls).deleted]);
    toHulls = toHulls(~[CellHulls(toHulls).deleted]);
    
    % Ignore frozen hulls
    bFrozenFam = ([CellFamilies.bFrozen]);
    frozenTracks = [CellFamilies(bFrozenFam).tracks];
    chkHulls = [CellTracks(frozenTracks).hulls];
    frozenHulls = chkHulls(chkHulls>0);
    
    fromHulls = setdiff(fromHulls,frozenHulls);
    toHulls = setdiff(toHulls,frozenHulls);
    
    
    % Update CachedCostMatrix
    fromMap = zeros(1,size(Costs,1));
    fromMap(fromHulls) = 1:length(fromHulls);
    
    bOtherEdges = any((GraphEdits(fromHulls,:) > 0),2);
    
    for j=1:length(toHulls)
        setCol = Costs(fromHulls,toHulls(j));
    
        % Zero edges other than added edits
        setCol(bOtherEdges) = 0;
        
        % Handle updating graph-edit related cache edges
        bAddedEdges = (GraphEdits(:,toHulls(j)) > 0);
        if ( nnz(bAddedEdges) > 0 )
            % Zero all edges but user edited ones, zero removed edges
            setCol = eps * GraphEdits(fromHulls,toHulls(j));
            setCol(setCol < 0) = 0;
        else
            % Remove costs associated with user removed edges
            rmFromEdge = fromMap(GraphEdits(:,toHulls(j)) < 0);
            rmFromEdge = rmFromEdge(rmFromEdge > 0);
            setCol(rmFromEdge) = 0;
        end
        
        CachedCostMatrix(fromHulls,toHulls(j)) = setCol;
    end
end

