% historyAction = ResegInitializeAction(preserveFamilies)
% Edit Action:
% 
% Initialize resegmentation state

function historyAction = ResegInitializeAction(preserveFamilies, tStart)
    global ResegState bResegPaused
    
    bResegPaused = false;
    ResegState = [];
    ResegState.preserveFamilies = preserveFamilies;
    ResegState.primaryTree = preserveFamilies(1);
    ResegState.currentTime = tStart;
    ResegState.SegEdits = {};
    
    historyAction = '';
end
