%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     This file is part of LEVer.exe
%     (C) 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function SwapHulls(time,track1,track2)
% SwapHulls(time,track1,track2) will swap the hulls at the given time in
% the given tracks

global CellTracks HashedCells

track1Hash = time - CellTracks(track1).startTime + 1;
track2Hash = time - CellTracks(track2).startTime + 1;

if(0>=track1Hash || 0>=track2Hash || ...
        track1Hash>length(CellTracks(track1).hulls) || track2Hash>length(CellTracks(track2).hulls))
    return
end

hull1 = CellTracks(track1).hulls(track1Hash);
hull2 = CellTracks(track2).hulls(track2Hash);
CellTracks(track1).hulls(track1Hash) = hull2;
CellTracks(track2).hulls(track2Hash) = hull1;

index = [HashedCells{time}.hullID]==hull1;
HashedCells{time}(index).trackID = track2;
index = [HashedCells{time}.hullID]==hull2;
HashedCells{time}(index).trackID = track1;
end
