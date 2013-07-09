
function StartDraw(axHandle)
    curPools = get(axHandle,'UserData');
    
    if ( isempty(curPools) )
        error('Uninitialized resource pool for this axis handle');
    end
    
    % Reset current usage counts for all pools
    for i=1:size(curPools.pools,1)
        curPools.pools{i,3}(1) = 0;
        
        visHandles = curPools.pools{i,2};
        set(visHandles, 'Visible','off', 'HitTest','off', 'HandleVisibility','off');
    end
    
    curPools.renderOrder = [];
    
    set(axHandle, 'UserData',curPools);
end
