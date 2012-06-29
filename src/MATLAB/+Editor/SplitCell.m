% [historyAction newTracks] = SplitCell(hullID, k)
% Edit Action:
% 
% Attempt to split specified hull into k pieces.

function [historyAction newTracks] = SplitCell(hullID, k, randState)
    oldTrackID = Hulls.GetTrackID(hullID);
    
    historyAction = '';
    
    globStream = RandStream.getGlobalStream();
    globStream.State = randState;
    
    newTracks = Segmentation.SplitHull(hullID, k);
    
    if ( isempty(newTracks) )
        return;
    end
    
    historyAction = 'Push';
end
