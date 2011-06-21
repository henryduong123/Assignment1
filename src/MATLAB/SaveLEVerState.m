%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     This file is part of LEVer.exe
%     (C) 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Saves all relevant global structures to the specified location
function SaveLEVerState(filename)
    global CellFamilies CellHulls CellTracks HashedCells Costs GraphEdits CONSTANTS ConnectedDist CellPhenotypes Log
    
    save(filename,'CellFamilies','CellHulls','CellTracks','HashedCells','Costs','GraphEdits','CONSTANTS',...
        'ConnectedDist','CellPhenotypes','Log');
end
