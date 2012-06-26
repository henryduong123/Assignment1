function hashList = GetCoreHashList()
    global CellHulls CellTracks CellFamilies CellFeatures HashedCells CellPhenotypes Costs GraphEdits
    
    hashList = cell(8,1);
    
    opt.Method = 'SHA-1';
    opt.Format = 'HEX';
    
    hashList{1} = Dev.DataHash(CellHulls, opt);
    hashList{2} = Dev.DataHash(CellTracks, opt);
    hashList{3} = Dev.DataHash(CellFamilies, opt);
    hashList{4} = Dev.DataHash(CellFeatures, opt);
    hashList{5} = Dev.DataHash(HashedCells, opt);
    hashList{6} = Dev.DataHash(CellPhenotypes, opt);
    hashList{7} = Dev.DataHash(Costs, opt);
    hashList{8} = Dev.DataHash(GraphEdits, opt);
end