% [historyAction bFinished] = ResegFrameAction(t)
% Edit Action:
% 
% Resegment a single frame

function [historyAction bFinished] = ResegFrameAction(t, tMax)
    global ResegState CellFamilies
    
    bFinished = false;
    
    preserveTracks = [CellFamilies(ResegState.preserveFamilies).tracks];
    newPreserveTracks = Segmentation.ResegFromTree.FixupSingleFrame(t, preserveTracks, tMax);

    ResegState.currentTime = t+1;
    
    historyAction.action = 'Push';
    historyAction.arg = t;
end