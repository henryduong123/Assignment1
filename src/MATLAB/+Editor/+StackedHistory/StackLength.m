
function stLen = StackLength(stackEntry)
    global HistoryStack
    
    if ( ~exist('stackEntry','var') )
        stackEntry = HistoryStack.level;
    end
    
    if ( isnumeric(stackEntry) )
        if ( stackEntry > HistoryStack.level || stackEntry < 1 )
            error('Attempt to access history stack out of bounds');
        end
        
        chkStack = HistoryStack(stackEntry).stack;
        
    else
        chkStack = stackEntry;
    end
    
    stLen = mod(chkStack.current - chkStack.bottom, chkStack.maxSize);
end
