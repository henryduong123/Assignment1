
function PopStack(editTime)
    global HistoryStack
    
    if ( isempty(HistoryStack) )
        error('Cannot pop stack from uninitialized history');
    end
    
    if ( HistoryStack.level == 1 )
%         error('Cannot pop root stack');
        return;
    end
    
    % A little arbitrarily use max edit time from the stack
    if ( ~exist('editTime','var') )
        editTime = max(HistoryStack.stack(HistoryStack.level-1).time);
    end
    
    if ( HistoryStack.stack(HistoryStack.level).pushedCount > 0 )
        Editor.StackedHistory.PushState(editTime,HistoryStack.level-1);
    end
    
    HistoryStack.stack(HistoryStack.level) = [];
    HistoryStack.level = HistoryStack.level - 1;
end
