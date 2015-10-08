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
    global CellTracks Figures

    [localLabels, revLocalLabels] = UI.GetLocalTreeLabels(Figures.tree.familyID);
    answer = inputdlg('Enter New Label','New Label',1,{UI.TrackToLocal(localLabels, trackID)});
    if(isempty(answer)),return,end;
    
    newTrackIDLocal = answer(1);
    newTrackID = UI.LocalToTrack(revLocalLabels, newTrackIDLocal);

    if ( newTrackID > length(CellTracks) )
        warn = sprintf('Track %s does not exist, use "Remove from Tree" instead.',newTrackIDLocal);
        warndlg(warn);
        return;
    end

    if(isempty(CellTracks(newTrackID).hulls))
        warn = sprintf('Track %s does not exist, cannot change',newTrackIDLocal);
        warndlg(warn);
        return
    end
    curHull = CellTracks(newTrackID).hulls(1);
    
    if ( newTrackID == trackID )
        warndlg('New label is the same as the current label.');
        return;
    end
    
    if ( time < CellTracks(newTrackID).startTime )
        warn = sprintf('Cannot change label from %d to %s, track %s does not exist until frame %d.',trackID, newTrackIDLocal,newTrackIDLocal, CellTracks(newTrackID).startTime);
        warndlg(warn);
        return
    end
    
    bOverride = 0;
    [bLocked, bCanChange] = Tracks.CheckLockedChangeLabel(trackID, newTrackID, time);
    if ( any(bLocked) )
        if ( ~bCanChange )
            resp = questdlg('This edit will affect the structure of tracks on a locked tree, do you wish to continue?', 'Warning: Locked Tree', 'Continue', 'Cancel', 'Cancel');
            if ( strcmpi(resp,'Cancel') )
                return;
            end
            
            bOverride = 1;
        else
            bErr = Editor.ReplayableEditAction(@Editor.LockedChangeLabelAction, trackID, newTrackID, time);
            if ( bErr )
                return;
            end
            
            Error.LogAction('LockedChangeLabel',trackID,newTrackID);
        end
    end

    if ( ~any(bLocked) || bOverride )
        bErr = Editor.ReplayableEditAction(@Editor.ChangeLabelAction, trackID,newTrackID,time);
        if ( bErr )
            return;
        end
        
        Error.LogAction('ChangeLabel',trackID,newTrackID);
    end

    newTrackID = Hulls.GetTrackID(curHull);
    UI.DrawTree(CellTracks(newTrackID).familyID);
    UI.DrawCells();
end
