
function histState = GetLEVerState()
    global CellFamilies CellTracks HashedCells CellHulls Costs GraphEdits CachedCostMatrix ConnectedDist Figures CellPhenotypes SegmentationEdits

    histState.CellFamilies = CellFamilies;
    histState.CellTracks = CellTracks;
    histState.HashedCells = HashedCells;
    histState.CellHulls = CellHulls;
    histState.Costs = Costs;
    histState.GraphEdits = GraphEdits;
    histState.CachedCostMatrix = CachedCostMatrix;
    histState.ConnectedDist = ConnectedDist;
    histState.selectedFamID = Figures.tree.familyID;
    histState.CellPhenotypes = CellPhenotypes;
    histState.SegmentationEdits = SegmentationEdits;
end
