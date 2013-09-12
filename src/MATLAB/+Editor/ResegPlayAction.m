% historyAction = ResegPlayAction(tStart)
% Edit Action:
% 
% Begin resegmenting (from pause)

function historyAction = ResegPlayAction(tStart)
    global bResegPaused
    
    bResegPaused = false;
    
    historyAction = '';
end
