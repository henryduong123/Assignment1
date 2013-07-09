
function DropStack()
    global HistoryStack
    
    if ( isempty(HistoryStack) )
        error('Cannot drop stack from uninitialized history');
    end
    
    if ( HistoryStack.level == 1 )
%         error('Cannot drop root stack');
        return;
    end
    
    HistoryStack.stack(HistoryStack.level) = [];
    HistoryStack.level = HistoryStack.level - 1;
end