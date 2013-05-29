
function histStruct = Init()
    global CONSTANTS
    
    histStruct = struct('history',{struct()}, 'time',{1}, 'maxSize',{CONSTANTS.historySize}, 'bottom',{1}, 'top',{1}, 'current',{1}, 'pushedCount',{0});
    histStruct.history = Editor.StackedHistory.GetLEVerState();
end
