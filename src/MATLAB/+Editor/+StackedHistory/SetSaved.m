
function SetSaved()
    global HistoryStack

    if ( isempty(HistoryStack) )
        return;
    end
    
%     if ( HistoryStack.level > 1 )
%         return;
%     end
    
    HistoryStack.saved = HistoryStack.stack(1).current;
end