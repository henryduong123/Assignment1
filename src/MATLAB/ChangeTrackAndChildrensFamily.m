function ChangeTrackAndChildrensFamily(oldFamilyID,newFamilyID,trackID)
%This will remove the tree rooted at the given trackID from the given
%oldFamily and put them in the newFamily
%This DOES NOT make the parent child relationship, it is just updates the
%CellFamilies data structure.

%--Eric Wait

global CellFamilies CellTracks

%get the full list of tracks to be updateded
trackList = traverseTree(newFamilyID,trackID);

%remove tracks from family
for i=1:length(trackList)
    CellTracks(trackList(i)).familyID = newFamilyID;
%     RemoveTrackFromFamily(trackList(i));
end

if(isempty(CellFamilies(oldFamilyID).tracks))
    CellFamilies(oldFamilyID).rootTrackID = [];
    CellFamilies(oldFamilyID).startTime = [];
    CellFamilies(oldFamilyID).endTime = [];
else
    %update times
    CellFamilies(oldFamilyID).startTime = min([CellTracks(CellFamilies(oldFamilyID).tracks).startTime]);
    CellFamilies(oldFamilyID).endTime = max([CellTracks(CellFamilies(oldFamilyID).tracks).endTime]);
end
end

function trackList = traverseTree(newFamilyID,trackID)
%recursive helper function to traverse tree and gather track IDs
%will add the tracks to the new family along the way
global CellFamilies CellTracks

RemoveTrackFromFamily(trackID);
%add track
CellFamilies(newFamilyID).tracks(end+1) = trackID;

%update times
if(CellTracks(trackID).startTime < CellFamilies(newFamilyID).startTime)
    CellFamilies(newFamilyID).startTime = CellTracks(trackID).startTime;
end
if(CellTracks(trackID).endTime > CellFamilies(newFamilyID).endTime)
    CellFamilies(newFamilyID).endTime = CellTracks(trackID).endTime;
end

trackList = trackID;
if(~isempty(CellTracks(trackID).childrenTracks))    
    for i=1:length(CellTracks(trackID).childrenTracks)
        trackList = [trackList traverseTree(newFamilyID, CellTracks(trackID).childrenTracks(i))];
    end
end
end
