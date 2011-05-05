%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     This file is part of LEVer.exe
%     (C) 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function curFamilyID = NewCellFamily(cellHullID,t)
%Create a empty Family that will contain one track that contains only one
%hull


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
