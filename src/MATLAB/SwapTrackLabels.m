%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     This file is part of LEVer.exe
%     (C) 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function SwapTrackLabels(time,trackID1,trackID2)
%This function will swap the hulls of the two tracks from the given time
%forward.  Any children will also be swaped


global CellTracks CellHulls SegmentationEdits

track1Hash = time - CellTracks(trackID1).startTime + 1;
track2Hash = time - CellTracks(trackID2).startTime + 1;

%Mark the hulls as edited
MarkHullAsEdited(CellTracks(trackID1).hulls(track1Hash),time);

%get the hulls to move
track1Hulls = CellTracks(trackID1).hulls(track1Hash:end);
track2Hulls = CellTracks(trackID2).hulls(track2Hash:end);

%clear out the hulls copied
CellTracks(trackID1).hulls(track1Hash:end) = [];
CellTracks(trackID2).hulls(track2Hash:end) = [];

%copy the hulls to the other track
if(CellTracks(trackID1).startTime + length(CellTracks(trackID1).hulls) - 1 ~= time)
    error('');
end
if(CellTracks(trackID2).startTime + length(CellTracks(trackID2).hulls) - 1 ~= time)
    error('');
end
CellTracks(trackID1).hulls = [CellTracks(trackID1).hulls track2Hulls];
CellTracks(trackID2).hulls = [CellTracks(trackID2).hulls track1Hulls];

%update times
% index = find(CellTracks(trackID1).hulls,1,'first');
% startTime1 = CellHulls(CellTracks(trackID1).hulls(index)).time;
% index = find(CellTracks(trackID2).hulls,1,'first');
% startTime2 = CellHulls(CellTracks(trackID2).hulls(index)).time;
% RehashCellTracks(trackID1,startTime1);
% RehashCellTracks(trackID2,startTime2);

CellTracks(trackID1).startTime = CellHulls(CellTracks(trackID1).hulls(1)).time;
CellTracks(trackID2).startTime = CellHulls(CellTracks(trackID2).hulls(1)).time;
CellTracks(trackID1).endTime = CellHulls(CellTracks(trackID1).hulls(find([CellTracks(trackID1).hulls]~=0,1,'last'))).time;
CellTracks(trackID2).endTime = CellHulls(CellTracks(trackID2).hulls(find([CellTracks(trackID2).hulls]~=0,1,'last'))).time;

%update HashedCells
UpdateHashedCellsTrackID(trackID1,track2Hulls,time);
UpdateHashedCellsTrackID(trackID2,track1Hulls,time);

%swap children
tempChildrenTracks = CellTracks(trackID1).childrenTracks;
CellTracks(trackID1).childrenTracks = CellTracks(trackID2).childrenTracks;
CellTracks(trackID2).childrenTracks = tempChildrenTracks;

for i=1:length(CellTracks(trackID1).childrenTracks)
    CellTracks(CellTracks(trackID1).childrenTracks(i)).parentTrack = trackID1;
end
for i=1:length(CellTracks(trackID2).childrenTracks)
    CellTracks(CellTracks(trackID2).childrenTracks(i)).parentTrack = trackID2;
end


%check to see if the children have moved to a new family
if(CellTracks(trackID1).familyID ~= CellTracks(trackID2).familyID)
    for i=1:length(CellTracks(trackID1).childrenTracks)
        ChangeTrackAndChildrensFamily(CellTracks(trackID2).familyID,CellTracks(trackID1).familyID,CellTracks(trackID1).childrenTracks(i));
    end
    for i=1:length(CellTracks(trackID2).childrenTracks)
        ChangeTrackAndChildrensFamily(CellTracks(trackID1).familyID,CellTracks(trackID2).familyID,CellTracks(trackID2).childrenTracks(i));
    end
end 

%check to see if either of the tracks are dead
familyIDs = [];
if(~isempty(GetTimeOfDeath(trackID1)))
    familyIDs = StraightenTrack(trackID1);
end
if(~isempty(GetTimeOfDeath(trackID2)))
    familyIDs = [familyIDs StraightenTrack(trackID2)];
end
if(~isempty(familyIDs))
    ProcessNewborns(familyIDs,SegmentationEdits.maxEditedFrame);
end
end
