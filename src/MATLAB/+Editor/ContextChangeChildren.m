% Maria Enokian
function ContextChangeChildren(familyID,time,trackID)
    global CellTracks
    global Figures

    
    newTrackID = inputdlg('Enter the node that needs to be swapped','Child Swap',1,{num2str(trackID)});
    if(isempty(newTrackID)),return,end;
    newTrackID = str2double(newTrackID(1));
    
  parentTrackID = CellTracks(trackID).parentTrack;
  if (isempty(parentTrackID))
       warndlg('This is the root node and will not be able to switch parents');
        return;
  end
    
    if ( newTrackID > length(CellTracks) )
        warn = sprintf('Track %d does not exist, use "Remove from Tree" instead.',newTrackID);
        warndlg(warn);
        return;
    end

    if(isempty(CellTracks(newTrackID).hulls))
        warn = sprintf('Track %d does not exist, cannot switch children',newTrackID);
        warndlg(warn);
        return
    end
    curHull = CellTracks(newTrackID).hulls(1);
    
    if ( newTrackID == parentTrackID )
        warndlg('These are the same cells');
        return;
    end
   % case with cells that already split and cells that aren't in the
   % current frame time.
    if ( 0 == Tracks.GetHullID(time, newTrackID) )
        warndlg('This cell does not exist in the current frame.');
        return;
    end
    
    if ( time < CellTracks(newTrackID).startTime )
        warn = sprintf('Cannot switch children from %d to %d, track %d does not exist until frame %d.',parentTrackID, newTrackID,newTrackID, CellTracks(newTrackID).startTime);
        warndlg(warn);
        return
    end

        
        bErr = Editor.ReplayableEditAction(@Editor.ChangeChildren,familyID,trackID, newTrackID, time);
        if ( bErr )
            return;
        end
        
        Error.LogAction('Children Swapped',parentTrackID,newTrackID);


    newTrackID = Hulls.GetTrackID(curHull);
    Tracker.UpdateHematoFluor(time);
    UI.DrawTree(CellTracks(newTrackID).familyID);
    UI.DrawCells();
end
