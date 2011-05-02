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

if(~any([CellTracks(CellTracks(newTrackID).childrenTracks).endTime]<CellTracks(oldTrackID).startTime))
    RemoveChildren(newTrackID);
    AddHullToTrack(CellTracks(oldTrackID).hulls(1),newTrackID,[]);
elseif(CellTracks(oldTrackID).startTime<CellTracks(newTrackID).startTime)
    %old before new
    if(~isempty(CellTracks(newTrackID).parentTrack))
        MoveMitosisUp(CellTracks(oldTrackID).startTime,...
            CellTracks(newTrackID).siblingTrack);
    end
    AddHullToTrack(CellTracks(oldTrackID).hulls(1),newTrackID,[]);
elseif(CellTracks(oldTrackID).startTime>CellTracks(newTrackID).endTime)
    %new before old
    if(~isempty(CellTracks(newTrackID).childrenTracks))
        MoveMitosisDown(CellTracks(oldTrackID).startTime,newTrackID);
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

ClearTrack(oldTrackID);
end
