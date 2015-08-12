% BuildConnectedDistance.m - Build or update cell connected-component
% distances in ConnectedDist sturcture.

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

function BuildConnectedDistance(updateCells, bUpdateIncoming, bShowProgress)
    global CellHulls ConnectedDist

    if ( ~exist('bUpdateIncoming', 'var') )
        bUpdateIncoming = 0;
    end
    
    if ( ~exist('bShowProgress', 'var') )
        bShowProgress = 0;
    end
    
    if ( isempty(ConnectedDist) )
        ConnectedDist = cell(1,max(updateCells));
    end
    
    hullPerims = containers.Map('KeyType','uint32', 'ValueType','any');
    
    for i=1:length(updateCells)
        if (bShowProgress)
            UI.Progressbar((i-1)/length(updateCells));
        end
        
        if ( CellHulls(updateCells(i)).deleted )
            continue;
        end
        
        ConnectedDist{updateCells(i)} = [];
        t = CellHulls(updateCells(i)).time;
        
        UpdateDistances(updateCells(i), t, t+1, hullPerims);
        UpdateDistances(updateCells(i), t, t+2, hullPerims);
        
        if ( bUpdateIncoming )
            UpdateDistances(updateCells(i), t, t-1, hullPerims);
            UpdateDistances(updateCells(i), t, t-2, hullPerims);
        end
    end
    
    if ( bShowProgress )
        UI.Progressbar(1);
    end
end

function UpdateDistances(updateCell, t, tNext, hullPerims)
    global CellHulls HashedCells CONSTANTS
    
    if ( tNext < 1 || tNext > length(HashedCells) )
        return;
    end
    
    tDist = abs(tNext-t);
    ccMaxDist = CONSTANTS.dMaxConnectComponent;
    if ( tDist > 1 )
        ccMaxDist = 1.5*CONSTANTS.dMaxConnectComponent;
    end
    
    nextCells = [HashedCells{tNext}.hullID];
    
    if ( isempty(nextCells) )
        return;
    end
    
    comDistSq = sum((ones(length(nextCells),1)*CellHulls(updateCell).centerOfMass - vertcat(CellHulls(nextCells).centerOfMass)).^2, 2);
    
    nextCells = nextCells(comDistSq <= ((tDist*CONSTANTS.dMaxCenterOfMass)^2));
    
    if ( isempty(nextCells) )
        return;
    end
    
    for i=1:length(nextCells)
        ccDist = Helper.CalcConnectedDistance(updateCell,nextCells(i), CONSTANTS.imageSize, hullPerims, CellHulls);
        
        if ( ccDist > ccMaxDist )
            continue;
        end
        
        SetDistance(updateCell, nextCells(i), ccDist, tNext-t);
    end
end

function SetDistance(updateCell, nextCell, dist, updateDir)
    global ConnectedDist
    
    if ( updateDir > 0 )
        ConnectedDist{updateCell} = [ConnectedDist{updateCell}; nextCell dist];
        
        % Sort hulls to match MEX code
        [~, sortIdx] = sort(ConnectedDist{updateCell}(:,1));
        ConnectedDist{updateCell} = ConnectedDist{updateCell}(sortIdx,:);
    else
        chgIdx = [];
        if ( ~isempty(ConnectedDist{nextCell}) )
            chgIdx = find(ConnectedDist{nextCell}(:,1) == updateCell, 1, 'first');
        end
        
        if ( isempty(chgIdx) )
            ConnectedDist{nextCell} = [ConnectedDist{nextCell}; updateCell dist];
        else
            ConnectedDist{nextCell}(chgIdx,:) = [updateCell dist];
        end
        
        % Sort hulls to match MEX code
        [~, sortIdx] = sort(ConnectedDist{nextCell}(:,1));
        ConnectedDist{nextCell} = ConnectedDist{nextCell}(sortIdx,:);
    end
end

