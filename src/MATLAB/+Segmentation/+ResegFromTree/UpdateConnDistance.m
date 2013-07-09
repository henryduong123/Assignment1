function connDist = UpdateConnDistance(updateHulls, hulls, hash)
    global ConnectedDist
    
    connDist = ConnectedDist;
    
    for i=1:length(updateHulls)
        if ( hulls(updateHulls(i)).deleted )
            continue;
        end
        
        connDist{updateHulls(i)} = [];
        t = hulls(updateHulls(i)).time;
        
        connDist = updateDistances(updateHulls(i), t, t+1, connDist, hulls, hash);
        connDist = updateDistances(updateHulls(i), t, t+2, connDist, hulls, hash);
        
        connDist = updateDistances(updateHulls(i), t, t-1, connDist, hulls, hash);
        connDist = updateDistances(updateHulls(i), t, t-2, connDist, hulls, hash);
    end
end

function connDist = updateDistances(updateCell, t, tNext, connDist, hulls, hash)
    global CONSTANTS
    
    if ( tNext < 1 || tNext > length(hash) )
        return;
    end
    
    tDist = abs(tNext-t);
    
    nextCells = [hash{tNext}.hullID];
    
    if ( isempty(nextCells) )
        return;
    end
    
    comDistSq = sum((ones(length(nextCells),1)*hulls(updateCell).centerOfMass - vertcat(hulls(nextCells).centerOfMass)).^2, 2);
    
    nextCells = nextCells(comDistSq <= ((tDist*CONSTANTS.dMaxCenterOfMass)^2));

    [r c] = ind2sub(CONSTANTS.imageSize, hulls(updateCell).indexPixels);
    for i=1:length(nextCells)
        [rNext cNext] = ind2sub(CONSTANTS.imageSize, hulls(nextCells(i)).indexPixels);

        isect = intersect(hulls(updateCell).indexPixels, hulls(nextCells(i)).indexPixels);
        if ( ~isempty(isect) )
            isectDist = 1 - (length(isect) / min(length(hulls(updateCell).indexPixels), length(hulls(nextCells(i)).indexPixels)));
            connDist = setDistance(updateCell, nextCells(i), isectDist, tNext-t, connDist);
            continue;
        end
        ccMinDistSq = Inf;
        for k=1:length(r)
            ccDistSq = (rNext-r(k)).^2 + (cNext-c(k)).^2;
            ccRowMin = min(ccDistSq);
            if ( ccRowMin < ccMinDistSq )
                ccMinDistSq = ccRowMin;
            end
            
            if ( ccRowMin < 1 )
                break;
            end
        end
        
        if ( abs(tNext-t) == 1 )
            ccMaxDist = CONSTANTS.dMaxConnectComponent;
        else
            ccMaxDist = 1.5*CONSTANTS.dMaxConnectComponent;
        end
        
        if ( ccMinDistSq > (ccMaxDist^2) )
            continue;
        end
        
        connDist = setDistance(updateCell, nextCells(i), sqrt(ccMinDistSq), tNext-t, connDist);
    end
end

function connDist = setDistance(updateCell, nextCell, dist, updateDir, connDist)
    if ( updateDir > 0 )
        connDist{updateCell} = [connDist{updateCell}; nextCell dist];
        
        % Sort hulls to match MEX code
        [sortHulls sortIdx] = sort(connDist{updateCell}(:,1));
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
        [sortHulls sortIdx] = sort(connDist{nextCell}(:,1));
        connDist{nextCell} = connDist{nextCell}(sortIdx,:);
    end
end