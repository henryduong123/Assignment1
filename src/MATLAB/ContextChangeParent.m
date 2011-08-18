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

function ContextChangeParent(trackID,time)
%Function for context menu call back


global CellTracks

newParentID = inputdlg('Enter New Parent','New Parent',1,{num2str(CellTracks(trackID).parentTrack)});
if(isempty(newParentID)),return,end;
newParentID = str2double(newParentID(1));

%error checking
if(0>=newParentID || length(CellTracks)<newParentID || isempty(CellTracks(newParentID).hulls))
    msgbox(['Parent ' num2str(newParentID) ' is not a valid cell'],'Parent Change','warn');
    return
end
if(CellTracks(newParentID).startTime > time)
    msgbox(['Parent ' num2str(newParentID) ' comes after ' num2str(trackID) ' consider a different edit.'],'Parent Change','warn');
    return
elseif(CellTracks(trackID).endTime < CellTracks(newParentID).startTime)
    msgbox(['Sister Cell ' num2str(trackID) ' exists completely before ' num2str(newParentID) ' consider a rename instead.'],'Parent Change','warn');
    return
end

oldParent = CellTracks(trackID).parentTrack;
History('Push');
try
    %TODO: update GraphEdits based on change parent
    ChangeTrackParent(newParentID,time,trackID);
catch errorMessage
    try
        ErrorHandeling(['ChangeTrackParent(' num2str(newParentID) ' ' num2str(time) ' ' num2str(trackID) ') -- ' errorMessage.message],errorMessage.stack);
        return
    catch errorMessage2
        fprintf('%s',errorMessage2.message);
        return
    end
end
LogAction(['Changed parent of ' num2str(trackID)],oldParent,newParentID);

DrawTree(CellTracks(newParentID).familyID);
DrawCells();
end
