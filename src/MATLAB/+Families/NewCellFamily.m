% NewCellFamily.m - Create a empty Family that will contain one track that
% contains only one hull

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

function curFamilyID = NewCellFamily(cellHullID,t)

global CellFamilies

if(isempty(CellFamilies))
    trackID = Families.NewCellTrack(1,cellHullID,t);
    CellFamilies = struct(...
        'rootTrackID',   {trackID},...
        'tracks',       {trackID},...
        'startTime',    {t},...
        'endTime',      {t});
    
    curFamilyID = 1;
else
    %get next family ID
    curFamilyID = length(CellFamilies) + 1;
    trackID = Families.NewCellTrack(curFamilyID,cellHullID,t);
    
    %setup defaults for family tree
    CellFamilies(curFamilyID).rootTrackID = trackID;
    CellFamilies(curFamilyID).tracks = trackID;
    CellFamilies(curFamilyID).startTime = t;
    CellFamilies(curFamilyID).endTime = t;
end

end
