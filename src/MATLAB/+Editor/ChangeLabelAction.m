% ChangeLabelAction(trackID,newTrackID,time)
% Edit Action:
% Changes trackID to newTrackID beginning at time.

function ChangeLabelAction(trackID, newTrackID, time)
    %TODO: This edit graph update may need to more complicated to truly
    %capture user edit intentions.
    Tracker.GraphEditSetEdge(newTrackID,trackID,time,true);
    Tracks.ChangeLabel(trackID,newTrackID,time);
    
    Families.ProcessNewborns();
end
