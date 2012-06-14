% droppedTracks = RemoveFromTree(removeTrackID,time)
% time is optional
% Is similar to RemoveFromTreePrune but keeps the other child.  This will
% straighten out the parent track with the sibling of the given track

% ChangeLog:
% EW 6/7/12 created
function droppedTracks = RemoveFromTree(removeTrackID,time)
global CellTracks

if (~exist('time','var'))
    time = CellTracks(removeTrackID).startTime;
end

parentID = CellTracks(removeTrackID).parentTrack;
siblingID = CellTracks(removeTrackID).siblingTrack;

%% Drop off the tree
droppedTracks = Families.RemoveFromTreePrune(removeTrackID,time);
if (Helper.WasDropped(siblingID,droppedTracks) && ~isempty(parentID))
    %reconect sibling
    droppedTracks = [droppedTracks Tracks.ChangeLabel(siblingID,parentID)];
    droppedTracks = setdiff(droppedTracks,siblingID);
end
end

