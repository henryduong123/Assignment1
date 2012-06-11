% droppedTracks = RemoveMitosis(removeTrackID)
% Is similar to RemoveFromTree but keeps the other child.  This will
% straighten out the parent track with the sibling of the given track

% ChangeLog:
% EW 6/7/12 created
function droppedTracks = RemoveMitosis(removeTrackID)
global CellTracks

parentID = CellTracks(removeTrackID).parentTrack;

if (isempty(parentID))
    error('No mitosis to remove for track %d',removeTrackID);
end

%% Drop the child off the tree
droppedTracks = Families.RemoveFromTree(removeTrackID);
droppedTracks = droppedTracks(droppedTracks~=removeTrackID);

%% Connect the other child to the previous parent
droppedTracks = Tracks.ChangeTrackID(droppedTracks,parentID);
if (length(droppedTracks)>2)
    list = sprintf(' %d, ',droppedTracks);
    error('Have the wrong number of tracks: %s',list);
end

%% Reconnect any children that fell off from the changeLabel
if (length(droppedTracks)==2)
    Families.ReconnectParentWithChildren(parentID,droppedTracks);
end
end

