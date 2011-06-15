%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     This file is part of LEVer.exe
%     (C) 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function RemoveHull(hullID, bDontUpdateTree)
% RemoveHull(hullID) will LOGICALLY remove the hull.  Which means that the
% hull will have a flag set that means that it does not exist anywhere and
% should not be drawn on the cells figure


global HashedCells CellHulls CellTracks CellFamilies SegmentationEdits

if ( ~exist('bDontUpdateTree','var') )
    bDontUpdateTree = 0;
end

trackID = GetTrackID(hullID);

if(isempty(trackID)),return,end

bNeedsUpdate = RemoveHullFromTrack(hullID, trackID);

%remove hull from HashedCells
time = CellHulls(hullID).time;
index = [HashedCells{time}.hullID]==hullID;
HashedCells{time}(index) = [];

CellHulls(hullID).deleted = 1;

RemoveSegmentationEdit(hullID, time);

if ( ~bDontUpdateTree && bNeedsUpdate )
    RemoveFromTree(CellTracks(trackID).startTime, trackID, 'yes');
    ProcessNewborns(1:length(CellFamilies),SegmentationEdits.maxEditedFrame);
end
end
