% historyAction = TreeInference()
% Edit Action:
% 
% Applies inference to attempt to improve tree structure.

function historyAction = TreeInference(families)
    [iters totalTime] = Families.LinkTrees(families);
    
    Helper.SweepDeleted();
    
    historyAction = 'Push';
end