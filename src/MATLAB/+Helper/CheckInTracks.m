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
    
    bRootTracks = arrayfun(@(x)(isempty(x.parentTrack)), CellTracks(tracks));
    bPastStart = ([CellTracks(tracks).startTime] < t) | (bAtStart & ~bRootTracks);
    
    bLeafTracks = arrayfun(@(x)(isempty(x.childrenTracks)), CellTracks(tracks));
    bBeforeEnd = ([CellTracks(tracks).endTime] > t) | bAtEnd;

    bInTrack = (bPastStart & (bBeforeEnd | bLeafTracks));
end