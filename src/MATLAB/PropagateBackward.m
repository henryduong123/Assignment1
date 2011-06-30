function PropagateBackward(time)
    global HashedCells CellTracks CellPhenotypes

    phenoTracks = unique(GetTrackID(CellPhenotypes.hulls(1,:)));

    hullList = [];
    for i=1:length(phenoCells)
        if ( GetTrackPhenotype(phenoTracks(i)) == 1 )
            markedIdx = GetTimeOfDeath(phenoTracks(i)) - CellTracks(phenoCells(i)).startTime + 1;
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