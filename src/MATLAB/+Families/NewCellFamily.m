% NewCellFamily.m - Create a empty Family that will contain one track that
% contains only one hull

% ChangeLog
% EW 6/6/12 t is no longer a requirement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     Copyright 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%     This file is part of LEVer - the tool for stem cell lineaging. See
%     https://pantherfile.uwm.edu/cohena/www/LEVer.html for details
% 
%     LEVer is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
%     LEVer is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
% 
%     You should have received a copy of the GNU General Public License
%     along with LEVer in file "gnu gpl v3.txt".  If not, see 
%     <http://www.gnu.org/licenses/>.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function curFamilyID = NewCellFamily(cellHullID)

global CellFamilies CellHulls

time = CellHulls(cellHullID).time;

if(isempty(CellFamilies))
    trackID = Tracks.NewCellTrack(1,cellHullID);
    CellFamilies = struct(...
        'rootTrackID',   {trackID},...
        'tracks',       {trackID},...
        'startTime',    {time},...
        'endTime',      {time});
    
    curFamilyID = 1;
else
    %get next family ID
    curFamilyID = length(CellFamilies) + 1;
    trackID = Tracks.NewCellTrack(curFamilyID,cellHullID);
    
    %setup defaults for family tree
    CellFamilies(curFamilyID).rootTrackID = trackID;
    CellFamilies(curFamilyID).tracks = trackID;
    CellFamilies(curFamilyID).startTime = time;
    CellFamilies(curFamilyID).endTime = time;
end

end