
% UpdateLog:
% EW 6/6/12 Created
function UpdateFamilyTimes( familyID )
global CellFamilies CellTracks

tracks = CellFamilies(familyID).tracks;

if (isempty(tracks))
    CellFamilies(familyID).endTime = [];
    CellFamilies(familyID).startTime = [];
    CellFamilies(familyID).correctedTime = [];
    
    CellFamilies(familyID).rootTrackID = [];
    CellFamilies(familyID).bLocked = false;
	CellFamilies(familyID).bCompleted = false;
    CellFamilies(familyID).bFrozen = false;
    CellFamilies(familyID).extFamily = [];
    return;
end

times = [CellTracks(tracks).endTime];
CellFamilies(familyID).endTime = max(times);

times = [CellTracks(tracks).startTime];
[CellFamilies(familyID).startTime index] = min(times);

if ( CellFamilies(familyID).correctedTime > CellFamilies(familyID).endTime )
    CellFamilies(familyID).correctedTime = CellFamilies(familyID).endTime;
end

CellFamilies(familyID).rootTrackID = tracks(index);
end
