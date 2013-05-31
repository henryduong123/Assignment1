% historyAction = ResegFinishAction()
% Edit Action:
% 
% Pause resegmentation

function historyAction = ResegPauseAction()
    global ResegState
    
    ResegState.bPaused = 1;
    
    Editor.History('PushStack');
    
    historyAction = '';
end
