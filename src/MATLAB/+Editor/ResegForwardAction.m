% historyAction = ResegForwardAction(tStart)
% Edit Action:
% 
% Single forward reseg (from pause)

function historyAction = ResegForwardAction()
    global bResegPaused
    
    bResegPaused = true;
    
    historyAction = '';
end
