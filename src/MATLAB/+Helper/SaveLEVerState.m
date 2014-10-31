% SaveLEVerState.m - Saves all relevant global structures to the specified location

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

function SaveLEVerState(filename)
    global CellFamilies CellHulls CellTracks HashedCells Costs GraphEdits CONSTANTS ConnectedDist CellPhenotypes Log ReplayEditActions FluorData ResegLinks EditList stains stainColors
    
    gVars = whos('CellFamilies','CellHulls','CellTracks','HashedCells','Costs','GraphEdits','CONSTANTS',...
                 'ConnectedDist','CellPhenotypes','Log','ReplayEditActions',...
                 'FluorData', 'ResegLinks', 'EditList', 'global');
	
	totalSize = sum([gVars.bytes])/1024/1024;
    
    saveParam = '';
    if ( totalSize > 2000 )
        saveParam = '-v7.3';
    end
    
    save(filename,'CellFamilies','CellHulls','CellTracks','HashedCells','Costs','GraphEdits','CONSTANTS',...
        'ConnectedDist','CellPhenotypes','Log','ReplayEditActions',...
        'FluorData', 'ResegLinks','stains','EditList','stainColors', saveParam);
end
