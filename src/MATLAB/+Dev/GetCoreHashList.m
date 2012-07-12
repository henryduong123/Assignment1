function hashList = GetCoreHashList()
    global CellHulls CellTracks CellFamilies HashedCells CellPhenotypes Costs GraphEdits
    
    hashList = cell(7,1);
    
    hashList{1} = mexHashData(CellHulls);
    hashList{2} = mexHashData(CellTracks, '-ignoreField','color');
    hashList{3} = mexHashData(CellFamilies);
    hashList{4} = mexHashData(HashedCells);
    hashList{5} = mexHashData(CellPhenotypes);
    hashList{6} = mexHashData(Costs);
    hashList{7} = mexHashData(GraphEdits);
end