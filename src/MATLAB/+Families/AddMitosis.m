% droppedTracks = AddMitosis(addTrack, ontoTrack, time)

% ChangeLog:
% EW 6/7/12 created
function droppedTracks = AddMitosis(addTrack, ontoTrack, time)
global CellTracks

if (~exist('time','var'))
    time = CellTracks(addTrack).startTime;
end

if (time>CellTracks(addTrack).startTime)
    addTrack = Families.RemoveFromTree(addTrack,time);
end

droppedTracks = Families.AddToTree(addTrack, ontoTrack);
end

