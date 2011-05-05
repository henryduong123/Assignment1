%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     This file is part of LEVer.exe
%     (C) 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function curCellTrackID = NewCellTrack(familyID,cellHullID,t)
%Creates a new track in the Family that contains just the given hull.
%***Use this with empty Families only***


global CellTracks

curCellTrackID = 1;

if(isempty(CellTracks))
    CellTracks = struct(...
        'familyID',         {familyID},...
        'parentTrack',      {[]},...
        'siblingTrack',     {[]},...
        'childrenTracks',   {[]},...
        'hulls',            {cellHullID},...
        'startTime',        {t},...
        'endTime',          {t},...
        'timeOfDeath',      {[]},...
        'color',            {GetNextColor()});
else
    %get next celltrack ID
    curCellTrackID = length(CellTracks) + 1;
    
    %setup track defaults
    CellTracks(curCellTrackID).familyID = familyID;
    CellTracks(curCellTrackID).parentTrack = [];
    CellTracks(curCellTrackID).siblingTrack = [];
    CellTracks(curCellTrackID).childrenTracks = [];
    CellTracks(curCellTrackID).hulls(1) = cellHullID;
    CellTracks(curCellTrackID).startTime = t;
    CellTracks(curCellTrackID).endTime = t;
    CellTracks(curCellTrackID).timeOfDeath = [];
    CellTracks(curCellTrackID).color = GetNextColor();
end
    
AddHashedCell(t,cellHullID,curCellTrackID);

end
