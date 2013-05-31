
function bHasPool = HasPool(axHandle)
    curPools = get(axHandle,'UserData');
    
    bHasPool = 0;
    
    if ( isempty(curPools) )
        return;
    end
    
    if ( ~iscell(curPools) )
        return;
    end
    
    bHasPool = 1;
end