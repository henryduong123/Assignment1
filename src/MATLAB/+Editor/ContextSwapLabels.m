% historyAction = ContextSwapLabels(trackA, trackB, time)
% Edit Action:
% 
% Swap tracking for tracks A and B beginning at specified time.

function historyAction = ContextSwapLabels(trackA, trackB, time)
    
    Tracker.GraphEditSetEdge(trackA, trackB, time);
    Tracker.GraphEditSetEdge(trackB, trackA, time);
    
    bLocked = Helper.CheckLocked([trackA trackB]);
    if ( any(bLocked) )
        Tracks.LockedSwapLabels(trackA, trackB, time);
    else
        Tracks.SwapLabels(trackA, trackB, time);
        Families.ProcessNewborns();
    end
    
    historyAction = 'Push';
end
