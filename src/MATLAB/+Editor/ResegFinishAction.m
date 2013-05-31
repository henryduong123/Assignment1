% historyAction = ResegFinishAction()
% Edit Action:
% 
% Finish resegmentation action, (push history)

function historyAction = ResegFinishAction()
    global ResegState
    
    if ( ResegState.bPaused )
        Editor.History('PopStack');
    end
    
    ResegState = [];
    
    historyAction = 'PopStack';
end
