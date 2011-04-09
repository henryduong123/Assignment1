function newFamilyID = RemoveFromTree(time,trackID)
%This will remove the track and any of its children from its current family
%and create a new family rooted at the given track

global CellFamilies CellTracks CellHulls

hash = time - CellTracks(trackID).startTime + 1;
oldFamilyID = CellTracks(trackID).familyID;
newFamilyID = NewCellFamily(CellTracks(trackID).hulls(hash),time);
newTrackID = CellFamilies(newFamilyID).rootTrackID;

for i=0:length(CellTracks(trackID).hulls(hash+1:end))
    if(CellTracks(trackID).hulls(hash+i)~=0)
        AddHullToTrack(CellTracks(trackID).hulls(hash+i),newTrackID,[]);
    end
    CellTracks(trackID).hulls(hash+i) = 0;
end

for i=1:length(CellTracks(trackID).childrenTracks)
    ChangeTrackAndChildrensFamily(oldFamilyID,newFamilyID,CellTracks(trackID).childrenTracks(i));
    CellTracks(CellTracks(trackID).childrenTracks(i)).parentTrack = newTrackID;
end
index = CellFamilies(oldFamilyID).tracks == trackID;
CellFamilies(oldFamilyID).tracks(index) = [];
CellFamilies(newFamilyID).tracks(end+1) = newTrackID;
CellTracks(newTrackID).familyID = newFamilyID;
CellTracks(newTrackID).childrenTracks = CellTracks(trackID).childrenTracks;

%clean up old track
if(isempty(find([CellTracks(trackID).hulls]~=0, 1)))
    if(~isempty(CellTracks(trackID).siblingTrack))
        if(~isempty(CellTracks(CellTracks(trackID).parentTrack).startTime))
            CombineTrackWithParent(CellTracks(trackID).siblingTrack);
        end
    end
    CellTracks(trackID).familyID = [];
    CellTracks(trackID).parentTrack = [];
    CellTracks(trackID).siblingTrack = [];
    CellTracks(trackID).childrenTracks = [];
    CellTracks(trackID).hulls = [];
    CellTracks(trackID).startTime = [];
    CellTracks(trackID).endTime = [];
    CellTracks(trackID).color = [];
else
    CellTracks(trackID).childrenTracks = [];
    index = find([CellTracks(trackID).hulls]~=0, 1,'last');
    CellTracks(trackID).endTime = CellHulls(CellTracks(trackID).hulls(index)).time;
end
end
