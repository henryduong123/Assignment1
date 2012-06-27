function hashList = GetCoreHashList()
    global CellHulls CellTracks CellFamilies CellFeatures HashedCells CellPhenotypes Costs GraphEdits
    
    hashList = cell(8,1);
    
    hashList{1} = mexHashData(CellHulls);
    hashList{2} = mexHashData(CellTracks, '-ignoreField','color');
    hashList{3} = mexHashData(CellFamilies);
    hashList{4} = mexHashData(CellFeatures);
    hashList{5} = mexHashData(HashedCells);
    hashList{6} = mexHashData(CellPhenotypes);
    hashList{7} = mexHashData(Costs);
    hashList{8} = mexHashData(GraphEdits);
end