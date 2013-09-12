% historyAction = ResegFinishAction()
% Edit Action:
% 
% Pause resegmentation

function historyAction = ResegPauseAction()
    global ResegState bResegPaused
    
    bResegPaused = true;
    
    historyAction = '';
end
