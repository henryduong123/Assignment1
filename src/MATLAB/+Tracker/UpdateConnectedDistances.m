function connDist = UpdateConnectedDistances(updateCell, t, tNext, hullPerims, connDist, hulls, hash)
    global CONSTANTS
    
    if ( tNext < 1 || tNext > length(hash) )
        return;
    end
    
    nextCells = [hash{tNext}.hullID];
    if ( isempty(nextCells) )
        return;
    end
    
    ccDist = Tracker.CalcHullConnectedDistances(updateCell, nextCells, hullPerims, hulls);
    
    tDist = abs(tNext-t);
    ccMaxDist = CONSTANTS.dMaxConnectComponent;
    if ( tDist > 1 )
        ccMaxDist = 1.5*CONSTANTS.dMaxConnectComponent;
    end
    
    for i=1:length(ccDist)
        if ( isinf(ccDist(i)) )
            continue;
        end
        
        if ( ccDist(i) > ccMaxDist  )
            continue;
        end
        
        connDist = setDistance(updateCell, nextCells(i), ccDist(i), tNext-t, connDist);
    end
end

function connDist = setDistance(updateCell, nextCell, dist, updateDir, connDist)
    if ( updateDir > 0 )
        connDist{updateCell} = [connDist{updateCell}; nextCell dist];
        
        % Sort hulls to match MEX code
        [~,sortIdx] = sort(connDist{updateCell}(:,1));
        connDist{updateCell} = connDist{updateCell}(sortIdx,:);
    else
        chgIdx = [];
        if ( ~isempty(connDist{nextCell}) )
            chgIdx = find(connDist{nextCell}(:,1) == updateCell, 1, 'first');
        end
        
        if ( isempty(chgIdx) )
            connDist{nextCell} = [connDist{nextCell}; updateCell dist];
        else
            connDist{nextCell}(chgIdx,:) = [updateCell dist];
        end
        
        % Sort hulls to match MEX code
        [~,sortIdx] = sort(connDist{nextCell}(:,1));
        connDist{nextCell} = connDist{nextCell}(sortIdx,:);
    end
end