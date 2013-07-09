
function bCanUndo = CanUndo(stackEntry)
    global HistoryStack
    
    bCanUndo = false;
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
    
    bCanUndo = (mod(curStack.current - curStack.bottom, curStack.maxSize) > 0);
end