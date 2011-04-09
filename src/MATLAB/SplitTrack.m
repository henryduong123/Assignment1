function newTrackID = SplitTrack(trackID,hullID)
%SplitTrack will break the given track off at the given hull and assign it
%a new trackID.  The new track will also be assigned as a child of the
%given track.  Returns the trackID of the new track, which is the first
%child of the given track.

global CellFamilies CellTracks

%get all the hulls that come after hullID (in time that is)
%this also assumes that hulls are ordered
hullIndex = find([CellTracks(trackID).hulls]==hullID);

if(1==hullIndex)
    error('Trying to split a track at its root. TrackID: %d, HullID: %d',trackID,hullID);
    return
elseif(isempty(hullIndex))
    error('Trying to split a track at a non-existent hull. TrackID: %d, HullID: %d',trackID,hullID);
    return
end

hullList = CellTracks(trackID).hulls(hullIndex:end);
CellTracks(trackID).hulls(hullIndex:end) = [];
CellTracks(trackID).endTime = CellTracks(trackID).startTime + length(CellTracks(trackID).hulls) - 1;

newTrackID = length(CellTracks(1,:)) + 1;

%create the new track
CellTracks(newTrackID).familyID = CellTracks(trackID).familyID;
CellTracks(newTrackID).parentTrack = trackID;
CellTracks(newTrackID).siblingTrack = [];
CellTracks(newTrackID).hulls = hullList;
CellTracks(newTrackID).startTime = CellTracks(trackID).startTime + hullIndex - 1;
CellTracks(newTrackID).endTime = CellTracks(newTrackID).startTime + length(hullList) - 1;
CellTracks(newTrackID).color = CellTracks(trackID).color;

%attach the parents children to the newTrack
CellTracks(newTrackID).childrenTracks = CellTracks(trackID).childrenTracks;
for i=1:length(CellTracks(newTrackID).childrenTracks)
    CellTracks(CellTracks(newTrackID).childrenTracks(i)).parent = newTrackID;
end
CellTracks(trackID).childrenTracks = newTrackID;

%update the family
trackIndex = length(CellFamilies(CellTracks(newTrackID).familyID).tracks) + 1;
CellFamilies(CellTracks(newTrackID).familyID).tracks(trackIndex) = newTrackID;

%update HashedCells
UpdateHashedCellsTrackID(newTrackID,hullList,CellTracks(newTrackID).startTime);

end
