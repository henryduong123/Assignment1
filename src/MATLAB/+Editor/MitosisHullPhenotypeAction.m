% [historyAction newTrack] = MitosisHullPhenotypeAction()
% Edit Action:

function [historyAction hullID] = MitosisHullPhenotypeAction(clickPoint, time, trackID)
    
    hullID = Hulls.FindHull(time, clickPoint);
    if ( hullID <= 0 )
        newTrackID = Segmentation.AddNewSegmentHull(clickPoint, time);
        hullID = Tracks.GetHullID(time, newTrackID);
    else
        newTrackID = Hulls.GetTrackID(hullID);
    end
    
    if ( newTrackID ~= trackID )
        newTrackID = Tracks.TearoffHull(hullID);
        Tracks.ChangeLabel(newTrackID, trackID, time);
    end
    
    historyAction = '';
end
