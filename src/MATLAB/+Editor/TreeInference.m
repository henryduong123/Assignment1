% historyAction = TreeInference()
% Edit Action:
% 
% Applies inference to attempt to improve tree structure.

function historyAction = TreeInference(families, stopTime)
    [iters totalTime] = Families.LinkTrees(families, stopTime);
    
    historyAction = 'Push';
end