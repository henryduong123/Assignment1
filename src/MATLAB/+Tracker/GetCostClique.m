
function [startHulls nextHulls] = GetCostClique(startHulls, nextHulls, tMax)
    global CellHulls Costs
    
%     costMatrix = Tracker.GetCostMatrix();
    costMatrix = Costs;
    
    startHulls = [];
    nextHulls = [];
    
    if ( isempty(nextHulls) )
        return;
    end
    
    if ( ~exist('tMax','var') )
        tMax = 1;
    end
    
    tNext = CellHulls(nextHulls(1)).time;
    tPrev = tNext-1;
    
    for i=1:10
        % Add new previous hulls
        newPrev = getPrevHulls(costMatrix, nextHulls);
        addPrev = setdiff(newPrev,[startHulls nextHulls]);
        
        bKeep = (abs([CellHulls(addPrev).time] - tNext) <= tMax);
        addPrev = addPrev(bKeep);
        
        startHulls = [startHulls addPrev];
        
        % Add new next hulls
        newNext = getNextHulls(costMatrix, startHulls);
        addNext = setdiff(newPrev,[startHulls nextHulls]);
        
        bKeep = (abs([CellHulls(addNext).time] - tPrev) <= tMax);
        addNext = addNext(bKeep);
        
        nextHulls = [nextHulls addNext];
    end
end

function prevHulls = getPrevHulls(costMatrix, hulls)
    [r c] = find(costMatrix(:,hulls) > 0);
    
    prevHulls = r.';
end

function nextHulls = getNextHulls(costMatrix, hulls)
    [r c] = find(costMatrix(hulls,:) > 0);
    
    nextHulls = c.';
end