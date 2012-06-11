% droppedTracks = ChangeLabel(currentTrack, desiredTrack, time)
% This will move the currentTrack's hulls and children to the desiredTrack
% and return any tracks other tracks that have been dropped from the tree
% time is an optional parameter.  If time is not specified, the whole
% currentTrack is changed to the desiredTrack

% ChangeLog:
% EW 6/7/12 created
function droppedTracks = ChangeLabel(currentTrack, desiredTrack, time)
global CellTracks

if (~exist('time','var'))
    time = CellTracks(currentTrack).startTime;
end

children = CellTracks(currentTrack).childrenTracks;

%Pass the work off to the lower function
droppedTracks = Tracks.ChangeTrackID(currentTrack,desiredTrack,time);

%Reattach any children that were dropped from the current track
if(length(intersect(droppedTracks,children))==2)
    Families.ReconnectParentWithChildren(desiredTrack,children);
    droppedTracks = setdiff(droppedTracks,children);
end
end