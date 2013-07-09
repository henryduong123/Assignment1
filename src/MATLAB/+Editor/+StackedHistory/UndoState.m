
function editTime = UndoState(stackEntry)
    global HistoryStack
    
    if ( ~exist('stackEntry','var') )
        stackEntry = HistoryStack.level;
    end
    
    if ( stackEntry > HistoryStack.level || stackEntry < 1 )
        error('Attempted to acces stack outside bounds');
    end
    
    curStack = HistoryStack.stack(stackEntry);
    
    if ( ~Editor.StackedHistory.CanUndo(stackEntry) )
        return;
    end
    
    oldIdx = curStack.current;
    nextIdx = modDec(curStack.current, curStack.maxSize);
    
    HistoryStack.stack(stackEntry).pushedCount = curStack.pushedCount - 1;
    
    HistoryStack.stack(stackEntry).current = nextIdx;
    Editor.StackedHistory.SetLEVerState(curStack.history(nextIdx));
    editTime = curStack.time(oldIdx);
end

function y = modInc(x,size)
    y = mod((x-1)+1, size) + 1;
end

function y = modDec(x, size)
    y = mod((x-1)-1, size) + 1;
end