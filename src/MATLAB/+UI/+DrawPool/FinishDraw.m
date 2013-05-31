
function FinishDraw(axHandle)
    curPools = get(axHandle,'UserData');
    
    if ( isempty(curPools) )
        error('Uninitialized resource pool for this axis handle');
    end
    
    % Reset max usage counts for all pools
    for i=1:size(curPools,1)
        visHandles = curPools{i,2}(1:curPools{i,3}(1));
        set(visHandles, 'Visible','on');
        
        curPools{i,3}(2) = curPools{i,3}(1);
    end
    
    set(axHandle, 'UserData',curPools);
end