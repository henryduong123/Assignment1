
function SetLEVerState(histState)
    global CellFamilies CellTracks HashedCells CellHulls Costs GraphEdits ResegLinks CachedCostMatrix ConnectedDist Figures CellPhenotypes SegmentationEdits ResegState MitosisEditStruct

    CellFamilies = histState.CellFamilies;
    CellTracks = histState.CellTracks;
    HashedCells = histState.HashedCells;
    CellHulls = histState.CellHulls;
    Costs = histState.Costs;
    GraphEdits = histState.GraphEdits;
    CachedCostMatrix = histState.CachedCostMatrix;
    ConnectedDist = histState.ConnectedDist;
    
    if ( ~isempty(Figures) && ~isempty(histState.selectedFamID) )
        Figures.tree.familyID = histState.selectedFamID;
    end
    
    CellPhenotypes = histState.CellPhenotypes;
    SegmentationEdits = histState.SegmentationEdits;
    ResegState = histState.ResegState;
    ResegLinks = histState.ResegLinks;
    MitosisEditStruct = histState.MitosisEditStruct;
end
