function PropagateBackward(time)
    global HashedCells CellTracks CellPhenotypes

    phenoTracks = [];
    if ( ~isempty(CellPhenotypes.hullPhenoSet) )
        phenoTracks = unique(GetTrackID(CellPhenotypes.hullPhenoSet(1,:)));
    end

    hullList = [];
    for i=1:length(phenoTracks)
        if ( GetTrackPhenotype(phenoTracks(i)) == 1 )
            markedIdx = GetTimeOfDeath(phenoTracks(i)) - CellTracks(phenoTracks(i)).startTime + 1;
            markedHull = CellTracks(phenoTracks(i)).hulls(markedIdx);
            if ( markedHull == 0 )
                continue;
            end
        else
            markedIdx = find(CellTracks(phenoTracks(i)).hulls, 1, 'last');
            if ( isempty(markedIdx) )
                continue;
            end
            markedHull = CellTracks(phenoTracks(i)).hulls(markedIdx);
        end

        hullList = [hullList markedHull];
    end

    curCells = [HashedCells{time}.hullID];
    if ( isempty(curCells) )
        return;
    end

    TrackBackPhenotype(hullList, curCells);
end