function AddSingleHullToTrack(oldTrackID,newTrackID)
% AddSingleHullToTrack(oldTrackID,newTrackID)
% This function is indended for the oldTrack to be just a single hull,
% typicaly when a hull has been split and now that new hull is being added
% to a track.  This function takes the hull and merges it into the
% newTrack.  The parent and child relationships of the newTrack will be
% maintained.

%--Eric Wait

global CellTracks HashedCells CellFamilies Figures

if(~isempty(CellTracks(oldTrackID).parentTrack) && ...
        ~isempty(CellTracks(oldTrackID).childrenTracks) && ...
        1~=length(CellTracks(oldTrackID).hulls))
    error([num2str(oldTrackID) ' is not a single hull track or has a parent/child']);
end

if(CellTracks(oldTrackID).startTime<CellTracks(newTrackID).startTime)
    %old before new
    if(~isempty(CellTracks(newTrackID).parentTrack))
        moveMitosisUp(CellTracks(oldTrackID).startTime,...
            CellTracks(newTrackID).siblingTrack);
    end
    AddHullToTrack(CellTracks(oldTrackID).hulls(1),newTrackID,[]);
elseif(CellTracks(oldTrackID).startTime>CellTracks(newTrackID).endTime)
    %new before old
    if(~isempty(CellTracks(newTrackID).childrenTracks))
        moveMitosisDown(CellTracks(oldTrackID).startTime,newTrackID);
    end
    AddHullToTrack(CellTracks(oldTrackID).hulls(1),newTrackID,[]);
else
    %old within new
    if(~isempty(find([HashedCells{Figures.time}.trackID]==newTrackID,1)))
        SwapTrackLabels(CellTracks(oldTrackID).startTime,oldTrackID,newTrackID);
    else
        AddHullToTrack(CellTracks(oldTrackID).hulls(1),newTrackID,[]);
    end
end

%clean out old track/family
familyID = CellTracks(oldTrackID).familyID;
CellFamilies(familyID).rootTrackID = [];
CellFamilies(familyID).tracks = [];
CellFamilies(familyID).startTime = [];
CellFamilies(familyID).endTime = [];
CellTracks(oldTrackID).familyID = [];
CellTracks(oldTrackID).parentTrack = [];
CellTracks(oldTrackID).siblingTrack = [];
CellTracks(oldTrackID).childrenTracks = [];
CellTracks(oldTrackID).hulls = [];
CellTracks(oldTrackID).startTime = [];
CellTracks(oldTrackID).endTime = [];
CellTracks(oldTrackID).timeOfDeath = [];
CellTracks(oldTrackID).color = [];
end

function moveMitosisUp(time,siblingTrackID)
global CellTracks

%remove hulls from parent
hash = time - CellTracks(CellTracks(siblingTrackID).parentTrack).startTime + 1;
hulls = CellTracks(CellTracks(siblingTrackID).parentTrack).hulls(hash:end);
CellTracks(CellTracks(siblingTrackID).parentTrack).hulls(hash:end) = 0;
RehashCellTracks(CellTracks(siblingTrackID).parentTrack,CellTracks(CellTracks(siblingTrackID).parentTrack).startTime);

%add hulls to sibling
for i=1:length(hulls)
    AddHullToTrack(hulls(i),siblingTrackID,[]);
end
end

function moveMitosisDown(time,trackID)
global CellTracks CellFamilies

remove = 0;
children = {};

for i=1:length(CellTracks(trackID).childrenTracks)
    if(CellTracks(CellTracks(trackID).childrenTracks(i)).endTime <= time)
        remove = 1;
        break
    end
    hash = time - CellTracks(CellTracks(trackID).childrenTracks(i)).startTime + 1;
    if(0<hash)
        children(i).startTime = CellTracks(CellTracks(trackID).childrenTracks(i)).startTime;
        children(i).hulls = CellTracks(CellTracks(trackID).childrenTracks(i)).hulls(1:hash);
    end
end

if(remove)
    RemoveChildren(trackID);
else
    for i=1:length(children)
        familyID = NewCellFamily(children(i).hulls(1),children(i).startTime);
        newTrackID = CellFamilies(familyID).rootTrackID;
        for j=2:length(children(i).hulls)
            AddHullToTrack(children(i).hulls(j),newTrackID,[]);
        end
    end
end
end
