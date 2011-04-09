function curCellTrackID = NewCellTrack(familyID,cellHullID,t)
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
