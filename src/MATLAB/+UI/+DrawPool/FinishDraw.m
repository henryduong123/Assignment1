
function FinishDraw(axHandle)
    curPools = get(axHandle,'UserData');
    
    if ( isempty(curPools) )
        error('Uninitialized resource pool for this axis handle');
    end
    
    if ( ~isempty(curPools.renderOrder) )
        allAxChildren = allchild(axHandle);
        
        bForcedOrder = ismember(allAxChildren,curPools.renderOrder);
        
        unorderedChildren = allAxChildren(~bForcedOrder);
        
        splitIdx = find(bForcedOrder, 1, 'last') - nnz(bForcedOrder);
        reorderChildren = [unorderedChildren(1:splitIdx); flipud(curPools.renderOrder); unorderedChildren((splitIdx+1):end)];
        
        set(axHandle, 'Children',reorderChildren);
    end
    
    % Reset max usage counts for all pools
    for i=1:size(curPools.pools,1)
        visHandles = curPools.pools{i,2}(1:curPools.pools{i,3}(1));
        set(visHandles, 'Visible','on', 'HitTest','on','HandleVisibility','on');
        
        curPools.pools{i,3}(2) = curPools.pools{i,3}(1);
    end
    
    set(axHandle, 'UserData',curPools);
end
