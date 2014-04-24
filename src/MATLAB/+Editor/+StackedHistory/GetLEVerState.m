
function histState = GetLEVerState()
    global CellFamilies CellTracks HashedCells CellHulls Costs GraphEdits ResegLinks CachedCostMatrix ConnectedDist Figures CellPhenotypes SegmentationEdits ResegState MitosisEditStruct

    histState.CellFamilies = CellFamilies;
    histState.CellTracks = CellTracks;
    histState.HashedCells = HashedCells;
    histState.CellHulls = CellHulls;
    histState.Costs = Costs;
    histState.GraphEdits = GraphEdits;
    histState.CachedCostMatrix = CachedCostMatrix;
    histState.ConnectedDist = ConnectedDist;
    
    histState.selectedFamID = [];
    if ( ~isempty(Figures) )
        histState.selectedFamID = Figures.tree.familyID;
    end
    
    histState.CellPhenotypes = CellPhenotypes;
    histState.SegmentationEdits = SegmentationEdits;
    histState.ResegState = ResegState;
    histState.ResegLinks = ResegLinks;
    histState.MitosisEditStruct = MitosisEditStruct;
end
