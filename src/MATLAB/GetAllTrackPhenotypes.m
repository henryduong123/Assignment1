function [phenotypes hullIDs] = GetAllTrackPhenotypes(trackID)
    global CellTracks
    
    hullIDs = [];
    phenotypes = [];
    
    if ( trackID < 0 || trackID > length(CellTracks) )
        return;
    end

    nzHulls = CellTracks(trackID).hulls(CellTracks(trackID).hulls > 0);
    hullPheno = getHullPhenos(nzHulls);
    
    phenotypes = hullPheno(hullPheno > 0);
    hullIDs = nzHulls(hullPheno > 0);
end

function phenos = getHullPhenos(hullIDs)
    global CellPhenotypes

    phenos = zeros(size(hullIDs));
    
    if ( isempty(CellPhenotypes.hullPhenoSet) )
        return;
    end
    
    [bMember idx] = ismember(hullIDs, CellPhenotypes.hullPhenoSet(1,:));
    phenos(bMember) = CellPhenotypes.hullPhenoSet(2,idx(bMember));
end

