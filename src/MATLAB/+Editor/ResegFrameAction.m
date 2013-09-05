% [historyAction bFinished] = ResegFrameAction(t, tMax, viewLims)
% Edit Action:
% 
% Resegment a single frame

function [historyAction bFinished] = ResegFrameAction(t, tMax, viewLims)
    global ResegState CellFamilies
    
    bFinished = false;
    
    preserveTracks = [CellFamilies(ResegState.preserveFamilies).tracks];
    newPreserveTracks = Segmentation.ResegFromTree.FixupSingleFrame(t, preserveTracks, tMax, viewLims);

    ResegState.currentTime = t+1;
    
    historyAction.action = 'Push';
    historyAction.arg = t;
end