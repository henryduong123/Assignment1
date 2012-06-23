% historyAction = TreeInference()
% Edit Action:
% 
% Applies inference to attempt to improve tree structure.

function historyAction = TreeInference()
    [iters totalTime] = Families.LinkFirstFrameTrees();
    
    Helper.SweepDeleted();
    
    historyAction = 'Push';
end