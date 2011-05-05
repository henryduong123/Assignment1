%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     This file is part of LEVer.exe
%     (C) 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function AddHullToTrack(hullID,trackID,previousHullID)
% function AddHullToTrack(hullID,trackID,previousHullID)
%The hullID will be added to the track
%
%If trackID is given, previousHullID is not used.  Safe to
%send [] for either trackID or previousHullID.
%Prereq to leave trackID empty - Track to be added to exists and the
%previousHullID exists in that track.  Also, it has been
%removed from any previous track assosiation.


global HashedCells CellTracks CellFamilies CellHulls

if(isempty(trackID))
    %find the track to add this hull to
    previousTime = CellHulls(previousHullID).time;
    index = find([HashedCells{previousTime}(:).hullID]==previousHullID);
    if(isempty(index))
        error('Previous CellHull -- %d not found!',previousHullID);
    end
    %add the hullID to track
    curTrackID = HashedCells{previousTime}(index).trackID;
else
    curTrackID = trackID;
end

time = CellHulls(hullID).time;
hash = time - CellTracks(curTrackID).startTime + 1;
if(0 >= hash)
    RehashCellTracks(curTrackID, time);
    CellTracks(curTrackID).startTime = time;
    hash = time - CellTracks(curTrackID).startTime + 1;
    if(CellFamilies(CellTracks(curTrackID).familyID).startTime > time)
        CellFamilies(CellTracks(curTrackID).familyID).startTime = time;
        %TODO: Check if any sibling and change mitosis
        %TODO: Check if this changes the root of the family
    end
end
CellTracks(curTrackID).hulls(hash) = hullID;

if(CellTracks(curTrackID).endTime < time)
    CellTracks(curTrackID).endTime = time;
    if(CellFamilies(CellTracks(curTrackID).familyID).endTime < time)
        CellFamilies(CellTracks(curTrackID).familyID).endTime = time;
    end
    %TODO: Check if any sibling where this might contradict
elseif(CellTracks(curTrackID).startTime > time)
    CellTracks(curTrackID).startTime = time;
    if(CellFamilies(CellTracks(curTrackID).familyID).startTime > time)
        CellFamilies(CellTracks(curTrackID).familyID).startTime = time;
    end
end

%add the trackID back to HashedHulls
AddHashedCell(time,hullID,curTrackID);

end
