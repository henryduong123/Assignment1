% [historyAction newTracks] = SplitCell(hullID, k)
% Edit Action:
% 
% Attempt to split specified hull into k pieces.

function [historyAction newTracks] = SplitCell(hullID, k)
    oldTrackID = Hulls.GetTrackID(hullID);
    
    historyAction = '';
    
    newTracks = Segmentation.SplitHull(hullID, k);
    
    if ( isempty(newTracks) )
        return;
    end
    
    historyAction = 'Push';
end
