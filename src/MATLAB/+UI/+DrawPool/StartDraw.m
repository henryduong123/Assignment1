
function StartDraw(axHandle)
    curPools = get(axHandle,'UserData');
    
    if ( isempty(curPools) )
        error('Uninitialized resource pool for this axis handle');
    end
    
    % Reset current usage counts for all pools
    for i=1:size(curPools,1)
        curPools{i,3}(1) = 0;
        
        visHandles = curPools{i,2};
        set(visHandles, 'Visible','off');
    end
    
    set(axHandle, 'UserData',curPools);
end