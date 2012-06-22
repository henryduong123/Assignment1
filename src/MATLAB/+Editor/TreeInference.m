% TreeInference()
% Edit Action:
% Applies inference to attempt to improve tree structure.

function TreeInference()
    [iters totalTime] = Families.LinkFirstFrameTrees();
    
    Helper.SweepDeleted();
end