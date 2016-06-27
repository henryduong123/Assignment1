% BuildConnectedDistance.m - Build or update cell connected-component
% distances in ConnectedDist sturcture.

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

function BuildConnectedDistance(updateCells, bUpdateIncoming, bShowProgress)
    global CellHulls HashedCells ConnectedDist

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
        
        ConnectedDist = Tracker.UpdateConnectedDistances(updateCells(i), t, t+1, hullPerims, ConnectedDist,CellHulls,HashedCells);
        ConnectedDist = Tracker.UpdateConnectedDistances(updateCells(i), t, t+2, hullPerims, ConnectedDist,CellHulls,HashedCells);
        
        if ( bUpdateIncoming )
            ConnectedDist = Tracker.UpdateConnectedDistances(updateCells(i), t, t-1, hullPerims, ConnectedDist,CellHulls,HashedCells);
            ConnectedDist = Tracker.UpdateConnectedDistances(updateCells(i), t, t-2, hullPerims, ConnectedDist,CellHulls,HashedCells);
        end
    end
    
    if ( bShowProgress )
        UI.Progressbar(1);
    end
end

