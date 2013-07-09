
function InitStack()
    global HistoryStack
    
    HistoryStack = struct('stack',{[]}, 'level',{1}, 'saved',{1});
    HistoryStack.stack = Editor.StackedHistory.Init();
    Editor.StackedHistory.SetSaved();
end
