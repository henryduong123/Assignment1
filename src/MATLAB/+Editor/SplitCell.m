% newTracks = SplitCell(hullID, k)
% Edit Action:
% Attempt to split specified hull into k pieces.

function newTracks = SplitCell(hullID, k)
    oldTrackID = Hulls.GetTrackID(hullID);
    
    newTracks = Segmentation.SplitHull(hullID, k);
end
