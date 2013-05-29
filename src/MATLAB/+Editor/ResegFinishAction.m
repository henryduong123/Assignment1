% historyAction = ResegFinishAction()
% Edit Action:
% 
% Finish resegmentation action, (push history)

function historyAction = ResegFinishAction()
    global ResegState bResegPaused
    
    bResegPaused = [];
    ResegState = [];
    
    historyAction = 'PopStack';
end
