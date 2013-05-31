
function PushStack()
    global HistoryStack
    
    if ( isempty(HistoryStack) )
        error('Cannot push stack onto uninitialized history');
    end
    
    HistoryStack.level = HistoryStack.level + 1;
    HistoryStack.stack(HistoryStack.level) = Editor.StackedHistory.Init();
end
