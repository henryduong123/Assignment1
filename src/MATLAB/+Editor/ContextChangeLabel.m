% ContextChangeLabel.m - Context menu callback function for changing track
% labels

% ChangeLog:
% EW 6/8/12 reviewed
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

function ContextChangeLabel(time,trackID)

global CellTracks

newTrackID = inputdlg('Enter New Label','New Label',1,{num2str(trackID)});
if(isempty(newTrackID)),return,end;
newTrackID = str2double(newTrackID(1));

try
    %TODO: This edit graph update may need to more complicated to truly
    %capture user edit intentions.
    Tracker.GraphEditSetEdge(newTrackID,trackID,time);
    Tracks.ChangeLabel(trackID,newTrackID,time);
    Editor.History('Push');
catch errorMessage
    Error.ErrorHandling(['ChangeLabel(' num2str(time) ' ' num2str(trackID) ' ' num2str(newTrackID) ') -- ' errorMessage.message],errorMessage.stack);
    return
end

Error.LogAction('ChangeLabel',trackID,newTrackID);

curHull = CellTracks(newTrackID).hulls(1);

Families.ProcessNewborns();

newTrackID = Hulls.GetTrackID(curHull);
UI.DrawTree(CellTracks(newTrackID).familyID);
UI.DrawCells();
end
