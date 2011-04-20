% Saves all relevant global structures to the specified location
function SaveLEVerState(filename)
    global CellFamilies CellHulls CellTracks HashedCells Costs CONSTANTS ConnectedDist CellPhenotypes
    
    save(filename,'CellFamilies','CellHulls','CellTracks','HashedCells','Costs','CONSTANTS',...
        'ConnectedDist','CellPhenotypes');
end
