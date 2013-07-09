
function bCanRedo = CanRedo(stackEntry)
    global HistoryStack
    
    bCanRedo = false;
    if ( isempty(HistoryStack) )
        return;
    end
    
    if ( ~exist('stackEntry','var') )
        stackEntry = HistoryStack.level;
    end
    
    if ( stackEntry > HistoryStack.level || stackEntry < 1 )
        error('Attempted to acces stack outside bounds');
    end
    
    curStack = HistoryStack.stack(stackEntry);
    
    bCanRedo = (mod(curStack.top - curStack.current, curStack.maxSize) > 0);
end