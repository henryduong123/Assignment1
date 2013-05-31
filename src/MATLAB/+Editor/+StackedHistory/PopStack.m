
function PopStack()
    global HistoryStack
    
    if ( isempty(HistoryStack) )
        error('Cannot pop stack from uninitialized history');
    end
    
    if ( HistoryStack.level == 1 )
%         error('Cannot pop root stack');
        return;
    end
    
    if ( HistoryStack.stack(HistoryStack.level).pushedCount > 0 )
        Editor.StackedHistory.PushState(HistoryStack.level-1);
    end
    
    HistoryStack.stack(HistoryStack.level) = [];
    HistoryStack.level = HistoryStack.level - 1;
end
