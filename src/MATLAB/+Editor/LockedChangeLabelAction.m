% historyAction = LockedChangeLabelAction(trackID, newTrackID, time)
% Edit Action:
% 
% Changes hull at time from trackID to newTrackID. Tries to preserve tree
% structure.

function historyAction = LockedChangeLabelAction(trackID, newTrackID, time)
    Tracker.GraphEditSetEdge(newTrackID,trackID,time,false);
    Tracks.LockedChangeLabel(trackID,newTrackID,time);
    
    historyAction = 'Push';
end
