% [historyAction bFinished] = ResegForwardAction(tStart)
% Edit Action:
% 
% Single forward reseg (from pause)

function [historyAction bFinished] = ResegForwardAction()
    global ResegState bResegPaused
    
    bResegPaused = 1;
    
    bFinished = Segmentation.ResegFromTreeInteractive();
    
    historyAction = '';
end
