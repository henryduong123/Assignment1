% Saves all relevant global structures to the specified location
function SaveLEVerState(filename)
    global CellFamilies CellHulls CellTracks HashedCells Costs CONSTANTS ConnectedDist CellPhenotypes Log
    
    save(filename,'CellFamilies','CellHulls','CellTracks','HashedCells','Costs','CONSTANTS',...
        'ConnectedDist','CellPhenotypes','Log');
end
