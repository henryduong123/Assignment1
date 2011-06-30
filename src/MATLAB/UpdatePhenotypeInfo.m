function UpdatePhenotypeInfo()
    global CellPhenotypes CellTracks
    
    netracks = find(arrayfun(@(x)(~isempty(x.phenotype)), CellTracks));
    bPhenoCells = ([CellTracks(netracks).phenotype] > 0);

    phenoTracks = netracks(bPhenoCells);
    
    oldCellPheno = CellPhenotypes;
    CellPhenotypes = struct('descriptions', {oldCellPheno.descriptions}, 'contextMenuID', {oldCellPheno.contextMenuID}, 'hullPhenoSet', cell(size(oldCellPheno)));
    
    for i=1:length(phenoTracks)
        phenotype = CellTracks(phenoTracks(i)).phenotype;
        if ( phenotype == 1 )
            markedTime = CellTracks(phenoTracks(i)).timeOfDeath;
            hash = markedTime - CellTracks(phenoTracks(i)).startTime + 1;
            markedHull = CellTracks(phenoTracks(i)).hulls(hash);
        else
            markedHull = CellTracks(phenoTracks(i)).hulls(find(CellTracks(phenoTracks(i)).hulls > 0,1,'last'));
        end
        
        if ( isempty(markedHull) || (markedHull == 0) )
            continue;
        end
        
        SetPhenotype(markedHull, phenotype, 0);
    end
    
    CellTracks = rmfield(CellTracks, 'phenotype');
    CellTracks = rmfield(CellTracks, 'timeOfDeath');
end

