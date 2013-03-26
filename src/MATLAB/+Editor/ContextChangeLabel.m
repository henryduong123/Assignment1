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

    if(isempty(CellTracks(newTrackID).hulls))
        warn = sprintf('Track %d does not exist, cannot change',newTrackID);
        warndlg(warn);
        return
    end
    curHull = CellTracks(newTrackID).hulls(1);
    
    if ( newTrackID == trackID )
        warndlg('New label is the same as the current label.');
        return;
    end
    
    if ( time < CellTracks(newTrackID).startTime )
        warn = sprintf('Cannot change label from %d to %d, track %d does not exist until frame %d.',trackID, newTrackID,newTrackID, CellTracks(newTrackID).startTime);
        warndlg(warn);
        return
    end
    
    % TODO: If locked, verify this edit is "safe" otherwise ask before
    % continuing

    bErr = Editor.ReplayableEditAction(@Editor.ChangeLabelAction, trackID,newTrackID,time);
    if ( bErr )
        return;
    end
    
    Error.LogAction('ChangeLabel',trackID,newTrackID);

    newTrackID = Hulls.GetTrackID(curHull);
    UI.DrawTree(CellTracks(newTrackID).familyID);
    UI.DrawCells();
end
