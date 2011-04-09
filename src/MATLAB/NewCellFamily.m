function curFamilyID = NewCellFamily(cellHullID,t)
global CellFamilies

if(isempty(CellFamilies))
    trackID = NewCellTrack(1,cellHullID,t);
    CellFamilies = struct(...
        'rootTrackID',   {trackID},...
        'tracks',       {trackID},...
        'startTime',    {t},...
        'endTime',      {t});
else
    %get next family ID
    curFamilyID = length(CellFamilies) + 1;
    trackID = NewCellTrack(curFamilyID,cellHullID,t);
    
    %setup defaults for family tree
    CellFamilies(curFamilyID).rootTrackID = trackID;
    CellFamilies(curFamilyID).tracks = trackID;
    CellFamilies(curFamilyID).startTime = t;
    CellFamilies(curFamilyID).endTime = t;
end

end
