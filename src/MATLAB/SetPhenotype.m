function SetPhenotype(hullID, phenotype, bActive)
    global CellPhenotypes

    if ( isempty(CellPhenotypes.hullPhenoSet) )
        CellPhenotypes.hullPhenoSet = zeros(2,0);
    end
    
    unsetTrackPhenotype(hullID);
    
    if ( bActive || phenotype == 0 )
        return;
    end
    
    [newHulls newIdx] = unique([CellPhenotypes.hullPhenoSet(1,:) hullID]);
    newPheno = [CellPhenotypes.hullPhenoSet(2,:) phenotype];
    
    CellPhenotypes.hullPhenoSet = [newHulls; newPheno(newIdx)];
    
    LogAction(['Activated phenotype ' CellPhenotypes.descriptions{phenotype} ' for track ' num2str(GetTrackID(hullID))]);
end

function unsetTrackPhenotype(hullID)
    trackID = GetTrackID(hullID);
    [oldPhen resetHulls] = GetAllTrackPhenotypes(trackID);
    
    unsetPhenotype(resetHulls);
end

function unsetPhenotype(hullIDs)
    global CellPhenotypes
    
    rmPhen = getHullPhenos(hullIDs);
    
    [newHulls newIdx] = setdiff(CellPhenotypes.hullPhenoSet(1,:), hullIDs);
    newPheno = CellPhenotypes.hullPhenoSet(2,newIdx);
    
    CellPhenotypes.hullPhenoSet = [newHulls; newPheno];
    
    if ( ~isempty(rmPhen) && all(rmPhen > 0) )
        LogAction(['Deactivated phenotype ' CellPhenotypes.descriptions{rmPhen(end)} ' for track ' num2str(GetTrackID(hullIDs(end)))]);
    end
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

