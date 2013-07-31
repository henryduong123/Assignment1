% bInTrack = CheckInTracks(tracks)
% 
% Check (for reseg or mitosis editing) if time t is within tracks.

function bInTrack = CheckInTracks(t, tracks, bIncludeStart, bIncludeEnd)
    global CellTracks
    
    if ( ~exist('bIncludeStart','var') )
        bIncludeStart = true;
    end
    
    if ( ~exist('bIncludeEnd','var') )
        bIncludeEnd = true;
    end
    
    bAtStart = ([CellTracks(tracks).startTime] == t) & (bIncludeStart ~= 0);
    bAtEnd = ([CellTracks(tracks).endTime] == t) & (bIncludeEnd ~= 0);
    
    bPastStart = ([CellTracks(tracks).startTime] < t) | bAtStart;
    bLeafTracks = arrayfun(@(x)(isempty(x.childrenTracks)), CellTracks(tracks));
    bBeforeEnd = ([CellTracks(tracks).endTime] > t) | bAtEnd;

    bInTrack = (bPastStart & (bBeforeEnd | bLeafTracks));
end