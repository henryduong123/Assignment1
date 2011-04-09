function ChangeTrackAndChildrensFamily(oldFamilyID,newFamilyID,trackID)
%This will remove the tree rooted at the given trackID from the given
%oldFamily and put them in the newFamily
%This DOES NOT make the parent child relationship, it is just updates the
%CellFamilies data structure.

global CellFamilies CellTracks

%get the full list of tracks to be updateded
trackList = traverseTree(newFamilyID,trackID);

%remove tracks from family
for i=1:length(trackList)
    CellTracks(trackList(i)).familyID = newFamilyID;
    index = CellFamilies(oldFamilyID).tracks == trackList(i);
    CellFamilies(oldFamilyID).tracks(index) = [];
end

if(isempty(CellFamilies(oldFamilyID).tracks))
    CellFamilies(oldFamilyID).rootTrackID = [];
    CellFamilies(oldFamilyID).startTime = [];
    CellFamilies(oldFamilyID).endTime = [];
else    
    %update times
    CellFamilies(oldFamilyID).startTime = CellTracks(CellFamilies(oldFamilyID).tracks(1)).startTime;
    CellFamilies(oldFamilyID).endTime = CellTracks(CellFamilies(oldFamilyID).tracks(1)).endTime;
    for i=2:length(CellFamilies(oldFamilyID).tracks)
        if(CellTracks(CellFamilies(oldFamilyID).tracks(i)).startTime < CellFamilies(oldFamilyID).startTime)
            CellFamilies(oldFamilyID).startTime = CellTracks(CellFamilies(oldFamilyID).tracks(i)).startTime;
        end
        if(CellTracks(CellFamilies(oldFamilyID).tracks(i)).endTime > CellFamilies(oldFamilyID).endTime)
            CellFamilies(oldFamilyID).endTime = CellTracks(CellFamilies(oldFamilyID).tracks(i)).endTime;
        end
    end
end
end

function trackList = traverseTree(newFamilyID,trackID)
%recursive helper function to traverse tree and gather track IDs
%will add the tracks to the new family along the way
global CellFamilies CellTracks

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
