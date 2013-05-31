
function SetLEVerState(histState)
    global CellFamilies CellTracks HashedCells CellHulls Costs GraphEdits CachedCostMatrix ConnectedDist Figures CellPhenotypes SegmentationEdits

    CellFamilies = histState.CellFamilies;
    CellTracks = histState.CellTracks;
    HashedCells = histState.HashedCells;
    CellHulls = histState.CellHulls;
    Costs = histState.Costs;
    GraphEdits = histState.GraphEdits;
    CachedCostMatrix = histState.CachedCostMatrix;
    ConnectedDist = histState.ConnectedDist;
    Figures.tree.familyID = histState.selectedFamID;
    CellPhenotypes = histState.CellPhenotypes;
    SegmentationEdits = histState.SegmentationEdits;
end
