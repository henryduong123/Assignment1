% AddToTree(addTrack, ontoTrack)
% Low level function that adds one onto another as a mitosis event
% Throws an error if:
%   addTrack.startTime < ontoTrack.startTime
%   addTrack.startTime > ontoTrack.endTime

% ChangLog
% EW 6/7/12 Created
function droppedTracks = AddToTree(addTrack, ontoTrack)
global CellTracks

%% Error Checking
if (CellTracks(addTrack).startTime<CellTracks(ontoTrack).startTime || ...
        CellTracks(addTrack).startTime>CellTracks(ontoTrack).endTime ||...
        CellTracks(addTrack).startTime==CellTracks(ontoTrack).startTime)
    error('Tried to add track %d (startTime: %d) onto track %d (startTime: %d, endTime: %d)',...
        addTrack,CellTracks(addTrack).startTime,ontoTrack,CellTracks(ontoTrack).startTime,...
        CellTracks(ontoTrack).endTime);
end

droppedTracks = Families.RemoveFromTree(addTrack);

%% Split the track that will be the parent
newSibling = Families.RemoveFromTree(ontoTrack,CellTracks(addTrack).startTime);

if (length(newSibling)~=1)
    list = sprintf(' %d, ',newSibling);
    error('Dropped too many tracks %s',list);
end

%% Add both the droppedTrack and the addTrack as children
Families.ReconnectParentWithChildren(ontoTrack,[addTrack newSibling]);
end