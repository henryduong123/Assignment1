
function PushState(stackEntry)
    global HistoryStack
    
    if ( ~exist('stackEntry','var') )
        stackEntry = HistoryStack.level;
    end
    
    if ( stackEntry > HistoryStack.level || stackEntry < 1 )
        error('Attempted to acces stack outside bounds');
    end
    
    curStack = HistoryStack.stack(stackEntry);
    
    nextIdx = modInc(curStack.current, curStack.maxSize);
    if ( nextIdx == curStack.bottom )
        HistoryStack.stack(stackEntry).bottom = modInc(curStack.bottom, curStack.maxSize);
    end
    
    if ( stackEntry == 1 && nextIdx == HistoryStack.saved )
        HistoryStack.saved = 0;
    end
    
    HistoryStack.stack(stackEntry).pushedCount = HistoryStack.stack(stackEntry).pushedCount + 1;
    
    HistoryStack.stack(stackEntry).top = nextIdx;
    HistoryStack.stack(stackEntry).current = nextIdx;
    HistoryStack.stack(stackEntry).history(nextIdx) = Editor.StackedHistory.GetLEVerState();
end

function y = modInc(x,size)
    y = mod((x-1)+1, size) + 1;
end

function y = modDec(x, size)
    y = mod((x-1)-1, size) + 1;
end
