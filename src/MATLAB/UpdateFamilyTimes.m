function UpdateFamilyTimes( familyID )
global CellFamilies CellTracks

tracks = CellFamilies(familyID).tracks;

if (isempty(tracks))
    CellFamilies(familyID).endTime = [];
    CellFamilies(familyID).startTime = [];
    CellFamilies(familyID).rootTrackID = [];
    return;
end

times = [CellTracks(tracks).endTime];
CellFamilies(familyID).endTime = max(times);
times = [CellTracks(tracks).startTime];
[CellFamilies(familyID).startTime index] = min(times);
CellFamilies(familyID).rootTrack = tracks(index);
end