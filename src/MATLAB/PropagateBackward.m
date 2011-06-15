function PropagateBackward(time)
    global HashedCells CellTracks
    
    netracks = find(arrayfun(@(x)(~isempty(x.phenotype)), CellTracks));
    bPhenoCells = ([CellTracks(netracks).phenotype] > 0);

    phenoCells = netracks(bPhenoCells);

    hullList = [];
    for i=1:length(phenoCells)
        if ( CellTracks(phenoCells(i)).phenotype == 1 )
            markedIdx = CellTracks(phenoCells(i)).timeOfDeath - CellTracks(phenoCells(i)).startTime + 1;
            markedHull = CellTracks(phenoCells(i)).hulls(markedIdx);
            if ( markedHull == 0 )
                continue;
            end
        else
            markedIdx = find(CellTracks(phenoCells(i)).hulls, 1, 'last');
            if ( isempty(markedIdx) )
                continue;
            end
            markedHull = CellTracks(phenoCells(i)).hulls(markedIdx);
        end

        hullList = [hullList markedHull];
    end

    curCells = [HashedCells{time}.hullID];
    if ( isempty(curCells) )
        return;
    end

    TrackBackPhenotype(hullList, curCells);
end