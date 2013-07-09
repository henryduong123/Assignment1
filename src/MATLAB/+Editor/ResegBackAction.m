% historyAction = ResegBackAction()
% Edit Action:
% 
% Back up a single frame, undoing whatever reseg actions were taken in the
% current frame

function historyAction = ResegBackAction()
    historyAction.action = 'Undo';
    historyAction.arg = 'Jump';
end
