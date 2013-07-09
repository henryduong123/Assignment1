% historyAction = ResegFinishAction()
% Edit Action:
% 
% Pause resegmentation

function historyAction = ResegPauseAction()
    global ResegState bResegPaused
    
    bResegPaused = 1;
    
    historyAction = '';
end
