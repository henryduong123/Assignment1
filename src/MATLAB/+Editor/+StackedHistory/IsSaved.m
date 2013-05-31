
function bSaved = IsSaved()
    global HistoryStack
    
    if ( HistoryStack.level > 1 )
        bSaved = 1;
        return;
    end
    
    curStack = HistoryStack.stack(1);
    
    bSaved = (curStack.current == HistoryStack.saved);
end