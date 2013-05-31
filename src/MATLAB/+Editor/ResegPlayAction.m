% [historyAction bFinished] = ResegPlayAction()
% Edit Action:
% 
% Begin resegmenting (from pause)

function [historyAction bFinished] = ResegPlayAction()
    global ResegState
    
    ResegState.bPaused = 0;
    
    Editor.History('PopStack');
    bFinished = Segmentation.ResegFromTreeInteractive();
    
    if ( bFinished )
        ResegState = [];
        Editor.History('PopStack');
    end
    
    historyAction = '';
end
