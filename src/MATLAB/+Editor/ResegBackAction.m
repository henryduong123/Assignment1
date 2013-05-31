% historyAction = ResegBackAction()
% Edit Action:
% 
% Back up a single frame, undoing whatever reseg actions were taken in the
% current frame

function historyAction = ResegBackAction()
    global Figures ResegState
    
    historyAction = '';
    if ( ResegState.currentTime < 2 )
        return;
    end
    
%     if ( ~Editor.StackedHistory.CanUndo(level) )
%     end
    
    Editor.History('DropStack');
    Editor.History('Undo');
    Editor.History('PushStack');
    
    ResegState.currentTime = ResegState.currentTime - 1;
    
    Figures.time = (ResegState.currentTime - 1);
    UI.DrawTree(ResegState.primaryTree);
    UI.DrawCells();
end
