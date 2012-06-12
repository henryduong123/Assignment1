% NewCellTrack.m - Creates a new track in the Family that contains just the
% given hull.
% ***Use this with empty Families only***

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
        'color',            {UI.GetNextColor()});
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
    CellTracks(curCellTrackID).color = UI.GetNextColor();
end
    
Hulls.AddHashedCell(cellHullID,curCellTrackID);

end
