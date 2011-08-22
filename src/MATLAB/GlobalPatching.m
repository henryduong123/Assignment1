function GlobalPatching()
    global CellFamilies CellTracks CellHulls CONSTANTS GraphEdits
    
    childHulls = arrayfun(@getRootHullID, CellFamilies, 'UniformOutput',0);
    childHulls = [childHulls{:}];
    
    costMatrix = GetCostMatrix();
    % Zero all secondary-edited mitosis edges so they cannot be patched
%     costMatrix(GraphEdits==2) = 0;
    % As stated elsewhere linear/binary indexing of large sparse cost
    % matrices is unsupported: see comments in GetCostMatrix()
    [r,c] = find(GraphEdits==2);
    for i=1:length(r)
        costMatrix(r(i),c(i)) = 0;
    end
    
    costMatrix = costMatrix(:,childHulls);
    parentHulls = find(any(costMatrix > 0,2));
    
    % Don't consider deleted hulls as parents
    bDeleted = [CellHulls(parentHulls).deleted];
    parentHulls = parentHulls(~bDeleted);
    
    costMatrix = costMatrix(parentHulls,:);
    
    while( nnz(costMatrix) > 0 )
        [r,c,val] = find(costMatrix);
        [dump,idx] = min(val);
        
        childTrack = GetTrackID(childHulls(c(idx)));
        parentTrack = GetTrackID(parentHulls(r(idx)));
        
        parentFuture = CellTracks(parentTrack).endTime - CellTracks(childTrack).startTime + 1;
        if ( parentFuture > CONSTANTS.minParentFuture )
            costMatrix(r(idx),c(idx)) = 0;
            continue;
        end
        
        childLength = CellTracks(childTrack).endTime - CellTracks(childTrack).startTime + 1;
        if ( childLength <= parentFuture )
            costMatrix(r(idx),c(idx)) = 0;
            continue;
        end
        
        if ( ~isempty(CellTracks(parentTrack).childrenTracks) )
            costMatrix(r(idx),c(idx)) = 0;
            continue;
        end
        
        if ( CellTracks(childTrack).startTime <= CellTracks(parentTrack).endTime )
            RemoveFromTree(CellTracks(childTrack).startTime, parentTrack, 'no');
        end
        
        ChangeLabel(CellTracks(childTrack).startTime, childTrack, parentTrack);
        RehashCellTracks(parentTrack,CellTracks(parentTrack).startTime);
        
        costMatrix(r(idx),:) = 0;
        costMatrix(:,c(idx)) = 0;
    end
end

function hullID = getRootHullID(family)
    global CellTracks
    
    if ( isempty(family.startTime) )
        hullID = [];
        return;
    end
    
    hullID = CellTracks(family.rootTrackID).hulls(1);
end
