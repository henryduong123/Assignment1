function ContextSwitchParent(familyID,time,trackID)
    global CellTracks
    global Figures
 
    newTrackID = inputdlg('Enter Desired Parent','New Parent',1,{num2str(trackID)});
    if(isempty(newTrackID)),return,end;
    newTrackID = str2double(newTrackID(1));
    
    if ( newTrackID > length(CellTracks) )
        warn = sprintf('Track %d does not exist, use "Remove from Tree" instead.',newTrackID);
        warndlg(warn);
        return;
    end

    if(isempty(CellTracks(newTrackID).hulls))
        warn = sprintf('Track %d does not exist, cannot switch parent',newTrackID);
        warndlg(warn);
        return
    end
    curHull = CellTracks(newTrackID).hulls(1);
    
    if ( newTrackID == trackID )
        warndlg('These are the same parents');
        return;
    end
    
    if ( time < CellTracks(newTrackID).startTime )
        warn = sprintf('Cannot switch parents from %d to %d, track %d does not exist until frame %d.',trackID, newTrackID,newTrackID, CellTracks(newTrackID).startTime);
        warndlg(warn);
        return
    end
    
%     bOverride = 0;
%     [bLocked bCanChange] = Tracks.CheckLockedChangeLabel(trackID, newTrackID, time);
%     if ( any(bLocked) )
%         if ( ~bCanChange )
%             resp = questdlg('This edit will affect the structure of tracks on a locked tree, do you wish to continue?', 'Warning: The Tree is Locked', 'Continue', 'Cancel', 'Cancel');
%             
%             if ( strcmpi(resp,'Cancel') )
%                 return;
%             end
%             
%             bOverride = 1;
%         else
%             bErr = Editor.ReplayableEditAction(@Editor.LockedChangeLabelAction, trackID, newTrackID, time);
%             if ( bErr )
%                 return;
%             end
%             
%             Error.LogAction('LockedChangeParent',trackID,newTrackID);
%         end
%     end

    %if ( ~any(bLocked) || bOverride )
        
        bErr = Editor.ReplayableEditAction(@Editor.SwitchParent,familyID,trackID, newTrackID, time);
        if ( bErr )
            return;
        end
        
        Error.LogAction('ChangeParent',trackID,newTrackID);
   % end

    newTrackID = Hulls.GetTrackID(curHull);
    Tracker.UpdateHematoFluor(time);
    UI.DrawTree(CellTracks(newTrackID).familyID);
    UI.DrawCells();
end
