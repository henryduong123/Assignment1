% bInTrack = CheckInTracks(tracks)
% 
% Check (for reseg or mitosis editing) if time t is within tracks.

function bInTrack = CheckInTracks(time, tracks)
    global CellTracks
    
    bPastStart = ([CellTracks(tracks).startTime] < time);
    bLeafTracks = arrayfun(@(x)(isempty(x.childrenTracks)), CellTracks(tracks));
    bBeforeEnd = ([CellTracks(tracks).endTime] > time);

    bInTrack = (bPastStart & (bBeforeEnd | bLeafTracks));
end