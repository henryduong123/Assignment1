% [historyAction bFinished] = ResegInitializeAction(preserveFamilies)
% Edit Action:
% 
% Initialize resegmentation state and begin playing

function [historyAction bFinished] = ResegInitializeAction(preserveFamilies, tStart)
    global ResegState
    
    ResegState = [];
    ResegState.preserveFamilies = preserveFamilies;
    ResegState.primaryTree = preserveFamilies(1);
    ResegState.currentTime = tStart;
    ResegState.bPaused = 0;
    ResegState.localHistory = Editor.StackedHistory.Init();
    
    Editor.History('PushStack');
    bFinished = Segmentation.ResegFromTreeInteractive();
    if ( bFinished )
        ResegState = [];
        Editor.History('PopStack');
    end
    
    historyAction = '';
end
