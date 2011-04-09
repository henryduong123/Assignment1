function ChangeLabel(time,oldTrackID,newTrackID)
%This will attempt to change the trackID from a given time until the end of
%the track.  However, the trackID will only be changed up to the point that
%the newTrackID does not exist.  If when moving hulls from the oldTrack to
%the newTrack, there is a hull already in the newTrack for a given frame,
%this function will return without moving any more hulls.
%
%If the whole oldTrack ends up moving over to the newTrack, and the
%oldTrack has a sibling, the oldTrack's sibling will be merged into the
%parent.
%
%Anytime that the oldTrack can be fully moved from the given time all the
%way to the endTime of the track, the oldTrack's subtree will move with it.
%The only time that the subtree would not move with the change would be as
%stated above.

global CellTracks CellFamilies CellHulls

bothHaveChildren = 0;%flag to deal with conflicting children
%flags to deal with position of tracks relitive to one another
oldBeforeNew = CellTracks(newTrackID).startTime > CellTracks(oldTrackID).endTime;
newBeforeOld = CellTracks(oldTrackID).startTime > CellTracks(newTrackID).endTime;
oldEmptied = 0;%flag to check to see if all the Hulls were moved from the oldTrack

%march through the hulls removing them from the oldTrack and adding them to
%the newTrack
oldTrackHashedTime = time - CellTracks(oldTrackID).startTime + 1;
newTrackHashedTime = time - CellTracks(newTrackID).startTime + 1;
hulls = CellTracks(oldTrackID).hulls(oldTrackHashedTime:end);
lastOldHull = hulls(end);

%if they both have children keep record of who's should be kept
if(~isempty(CellTracks(oldTrackID).childrenTracks) && ~isempty(CellTracks(newTrackID).childrenTracks))
    bothHaveChildren = 1;
end

for i=1:length(hulls)
    if((newTrackHashedTime+i-1>0 && newTrackHashedTime+i-1<length(CellTracks(newTrackID).hulls)) &&...
            CellTracks(newTrackID).hulls(newTrackHashedTime+i-1)~=0),break,end;
    if(hulls(i)~=0)
        AddHullToTrack(hulls(i),newTrackID,[]);
    end
    CellTracks(oldTrackID).hulls(oldTrackHashedTime+i-1) = 0;
end

firstHull = find(CellTracks(oldTrackID).hulls,1);
if(isempty(firstHull))
    oldEmptied = 1;
else
    firstHull = CellTracks(oldTrackID).hulls(firstHull);
    RehashCellTracks(oldTrackID,CellHulls(firstHull).time);
end

%Handle children
if(oldEmptied)
    %update parent and sibling   
    if(~isempty(CellTracks(oldTrackID).siblingTrack))
        CombineTrackWithParent(CellTracks(oldTrackID).siblingTrack);
        index = CellTracks(CellTracks(oldTrackID).parentTrack).childrenTracks == oldTrackID;
        CellTracks(CellTracks(oldTrackID).parentTrack).childrenTracks(index) = [];
    end
    
    %update family
    index = [CellFamilies(CellTracks(oldTrackID).familyID).tracks]==oldTrackID;
    CellFamilies(CellTracks(oldTrackID).familyID).tracks(index) = [];
    
    %clean up other fields
    CellTracks(oldTrackID).parentTrack = [];
    CellTracks(oldTrackID).siblingTrack = [];
    CellTracks(oldTrackID).startTime = [];
    CellTracks(oldTrackID).endTime = [];
    CellTracks(oldTrackID).color = [];
    
    %deal with any children
    if(oldBeforeNew)
        if(~isempty(CellTracks(oldTrackID).childrenTracks))
            dropChildren(CellTracks(oldTrackID).childrenTracks);
        end
    elseif(newBeforeOld)
        if(bothHaveChildren)
            dropChildren(CellTracks(newTrackID).childrenTracks);
            moveChildren(oldTrackID,newTrackID);
        elseif(~isempty(CellTracks(newTrackID).childrenTracks))
            dropChildren(CellTracks(newTrackID).childrenTracks);
        elseif(~isempty(CellTracks(oldTrackID).childrenTracks))
            moveChildren(oldTrackID,newTrackID);
        end
    end
else %the old track still exists in some fasion
    if(isempty(find(CellTracks(oldTrackID).hulls==lastOldHull, 1)) &&...
            ~isempty(CellTracks(oldTrackID).childrenTracks))
        %the last hull from the old track has been moved over and had
        %children
        if(CellHulls(lastOldHull).time<CellTracks(newTrackID).endTime)
            dropChildren(CellTracks(oldTrackID).childrenTracks);
        elseif(CellHulls(lastOldHull).time>=CellTracks(newTrackID).endTime)
            if(~isempty(CellTracks(newTrackID).childrenTracks))
                dropChildren(CellTracks(newTrackID).childrenTracks);
            end
            moveChildren(oldTrackID,newTrackID);
        end
    elseif(isempty(find(CellTracks(oldTrackID).hulls==lastOldHull, 1)) &&...
            CellHulls(lastOldHull).time>CellTracks(newTrackID).endTime &&...
            ~isempty(CellTracks(newTrackID).childrenTracks))
        dropChildren(CellTracks(newTrackID).childrenTracks);
    end
end
end

function dropChildren(children)
%remove children from tree
global CellTracks

familyIDs = [];
for i=1:length(children)
    familyIDs = [familyIDs RemoveFromTree(CellTracks(children(i)).startTime,children(i))];
end
%run processNewborns on them
ProcessNewborns(familyIDs);
end

function moveChildren(oldTrackID,newTrackID)
global CellTracks
if(isempty(CellTracks(oldTrackID).childrenTracks))
    %no children
elseif(isempty(CellTracks(newTrackID).childrenTracks))
    CellTracks(newTrackID).childrenTracks = CellTracks(oldTrackID).childrenTracks;
    if(CellTracks(oldTrackID).familyID ~= CellTracks(newTrackID).familyID)
        for i=1:length(CellTracks(oldTrackID).childrenTracks)
            ChangeTrackAndChildrensFamily(CellTracks(oldTrackID).familyID,CellTracks(newTrackID).familyID,CellTracks(oldTrackID).childrenTracks(i));
        end
    end
    CellTracks(oldTrackID).childrenTracks = [];
else
    error('Children conflict');
end
end
