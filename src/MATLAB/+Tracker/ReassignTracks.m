% ReassignTracks.m - Using cost submatrix appropriately reassign tracking
% over the given hulls.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     Copyright 2011-2016 Andrew Cohen
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

function changedHulls = ReassignTracks(costMatrix, extendHulls, affectedHulls, changedHulls, allowedChange)
    if ( ~exist('changedHulls','var') )
        changedHulls = [];
    end
    
    if ( ~exist('allowedChange','var') )
        allowedChange = affectedHulls;
    end
    
    bAllowedChange = ismember(affectedHulls, allowedChange);
    
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
        
        if ( ~bAllowedChange(bestOutgoing(matchedIdx(i))) )
            continue;
        end
        
        change = Tracker.AssignEdge(extHull, assignHull);
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
        
        if ( bAllowedChange(c) )
            change = Tracker.AssignEdge(extHull, assignHull);
            changedHulls = [changedHulls change];
        end
        
        costMatrix(r,:) = Inf;
        costMatrix(:,c) = Inf;
        
        [minCost minIdx] = min(costMatrix(:));
    end
    
    changedHulls = unique(changedHulls);
end
