%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     This file is part of LEVer.exe
%     (C) 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ChangeLabel(time,oldTrackID,newTrackID)
%ChangLabel(time,oldTrackID,newTrackID)
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


global CellTracks CellHulls

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
    if(newTrackHashedTime+i-1<0 || (newTrackHashedTime+i-1<length(CellTracks(newTrackID).hulls) &&...
            CellTracks(newTrackID).hulls(newTrackHashedTime+i-1)~=0)),break,end;
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

if(oldEmptied)
    if(oldBeforeNew)
        %deal with any children
        if(~isempty(CellTracks(oldTrackID).childrenTracks))
            RemoveChildren(oldTrackID);
        end
        if(~isempty(CellTracks(newTrackID).siblingTrack) && ...
                isempty(find(CellTracks(oldTrackID).childrenTracks==CellTracks(newTrackID).siblingTrack, 1)))
            CombineTrackWithParent(CellTracks(newTrackID).siblingTrack);
        end
        CellTracks(newTrackID).parentTrack = CellTracks(oldTrackID).parentTrack;
        index = CellTracks(CellTracks(newTrackID).parentTrack).childrenTracks==oldTrackID;
        CellTracks(CellTracks(newTrackID).parentTrack).childrenTracks(index) = newTrackID;
        CellTracks(newTrackID).siblingTrack = CellTracks(oldTrackID).siblingTrack;
        CellTracks(newTrackID).familyID = CellTracks(oldTrackID).familyID;
    elseif(newBeforeOld)
        %deal with any children
        if(bothHaveChildren)
            index = CellTracks(newTrackID).childrenTracks==oldTrackID;
            if(~isempty(find(index, 1)))
                RemoveFromTree(CellTracks(CellTracks(newTrackID).childrenTracks(~index)).startTime,...
                    CellTracks(newTrackID).childrenTracks(~index),'no');
                CellTracks(newTrackID).childrenTracks = [];
                CellTracks(oldTrackID).siblingTrack = [];
            else
                RemoveChildren(newTrackID);
            end
            moveChildren(oldTrackID,newTrackID);
        elseif(~isempty(CellTracks(newTrackID).childrenTracks))
            index = CellTracks(newTrackID).childrenTracks==oldTrackID;
            if(~isempty(find(index, 1)))
                RemoveFromTree(CellTracks(CellTracks(newTrackID).childrenTracks(~index)).startTime,...
                    CellTracks(newTrackID).childrenTracks(~index),'no');
                CellTracks(newTrackID).childrenTracks = [];
                CellTracks(oldTrackID).siblingTrack = [];
            else
                RemoveChildren(newTrackID);
            end
        elseif(~isempty(CellTracks(oldTrackID).childrenTracks))
            moveChildren(oldTrackID,newTrackID);
        end
        if(~isempty(CellTracks(oldTrackID).siblingTrack) && ...
                isempty(find(CellTracks(newTrackID).childrenTracks==CellTracks(oldTrackID).siblingTrack, 1)))
            CombineTrackWithParent(CellTracks(oldTrackID).siblingTrack);
        end
    end
    
    %clean up other fields
    RemoveTrackFromFamily(oldTrackID);
    ClearTrack(oldTrackID);
else %the old track still exists in some fasion
    if(isempty(find(CellTracks(oldTrackID).hulls==lastOldHull, 1)) &&...
            ~isempty(CellTracks(oldTrackID).childrenTracks))
        %the last hull from the old track has been moved over and had
        %children
        if(CellHulls(lastOldHull).time<CellTracks(newTrackID).endTime)
            RemoveChildren(oldTrackID);
        elseif(CellHulls(lastOldHull).time>=CellTracks(newTrackID).endTime)
            if(~isempty(CellTracks(newTrackID).childrenTracks))
                RemoveChildren(newTrackID);
            end
            moveChildren(oldTrackID,newTrackID);
        end
    elseif(~isempty(CellTracks(newTrackID).childrenTracks) && ...
            (((isempty(find(CellTracks(oldTrackID).hulls==lastOldHull, 1)) &&...
            CellHulls(lastOldHull).time>CellTracks(newTrackID).endTime)) || ...
            any([CellTracks(CellTracks(newTrackID).childrenTracks).startTime]<CellTracks(newTrackID).endTime)))
        RemoveChildren(newTrackID);
    end
end

%check to see if either of the tracks are dead
familyIDs = [];
if(~isempty(CellTracks(oldTrackID).timeOfDeath))
    familyIDs = StraightenTrack(oldTrackID);
end
if(~isempty(CellTracks(newTrackID).timeOfDeath))
    familyIDs = [familyIDs StraightenTrack(newTrackID)];
end
if(~isempty(familyIDs))
    ProcessNewborns(familyIDs);
end
end

function moveChildren(oldTrackID,newTrackID)
global CellTracks
if(isempty(CellTracks(oldTrackID).childrenTracks))
    %no children
elseif(isempty(CellTracks(newTrackID).childrenTracks))
    CellTracks(newTrackID).childrenTracks = CellTracks(oldTrackID).childrenTracks;
    for i=1:length(CellTracks(newTrackID).childrenTracks)
        CellTracks(CellTracks(newTrackID).childrenTracks(i)).parentTrack = newTrackID;
    end
    
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
