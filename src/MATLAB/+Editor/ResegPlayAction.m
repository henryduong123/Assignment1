% [historyAction bFinished] = ResegPlayAction(tStart)
% Edit Action:
% 
% Begin resegmenting (from pause)

function [historyAction bFinished] = ResegPlayAction(tStart)
    global ResegState bResegPaused
    
    bResegPaused = 0;
    
    bFinished = Segmentation.ResegFromTreeInteractive();
    
    historyAction = '';
end
