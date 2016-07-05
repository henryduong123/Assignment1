
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


function [startHulls nextHulls] = GetCostClique(startHulls, nextHulls, tMax)
    global CellHulls Costs
    
%     costMatrix = Tracker.GetCostMatrix();
    costMatrix = Costs;
    
    if ( isempty(nextHulls) )
        return;
    end
    
    if ( ~exist('tMax','var') )
        tMax = 1;
    end
    
    tNext = CellHulls(nextHulls(1)).time;
    tPrev = tNext-1;
    
    for i=1:10
        % Add new previous hulls
        newPrev = getPrevHulls(costMatrix, nextHulls);
        addPrev = setdiff(newPrev,[startHulls nextHulls]);
        
        bKeep = (abs([CellHulls(addPrev).time] - tNext) <= tMax);
        addPrev = addPrev(bKeep);
        
        startHulls = [startHulls addPrev];
        
        % Add new next hulls
        newNext = getNextHulls(costMatrix, startHulls);
        addNext = setdiff(newNext,[startHulls nextHulls]);
        
        bKeep = (abs([CellHulls(addNext).time] - tPrev) <= tMax);
        addNext = addNext(bKeep);
        
        if ( isempty(addNext) )
            break;
        end
        
        nextHulls = [nextHulls addNext];
    end
end

function prevHulls = getPrevHulls(costMatrix, hulls)
    [r c] = find(costMatrix(:,hulls) > 0);
    
    prevHulls = r.';
end

function nextHulls = getNextHulls(costMatrix, hulls)
    [r c] = find(costMatrix(hulls,:) > 0);
    
    nextHulls = c.';
end