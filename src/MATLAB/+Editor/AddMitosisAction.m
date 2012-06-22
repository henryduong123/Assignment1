% AddMitosisAction(parentTrack, leftChild, siblingTrack, time)
% Edit Action:
% Add siblingTrack as a mitosis event from parentTrack at time. If
% leftChild is non-empty also change its label to the parent track before
% adding the mitosis.

function AddMitosisAction(parentTrack, leftChild, siblingTrack, time)
    global CellTracks
    
    if ( ~isempty(leftChild) )
        Tracks.ChangeLabel(leftChild,parentTrack);
    end
    
    % if the sibling has history get rid of it
    if (CellTracks(siblingTrack).startTime<time)
        siblingTrack = Families.RemoveFromTreePrune(siblingTrack,time);
    end
    
    Tracker.GraphEditAddMitosis(parentTrack, siblingTrack, time);
    droppedTracks = Families.AddMitosis(siblingTrack, parentTrack);
end
