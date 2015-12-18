% ContextChangeParent.m - Allows user to correct the parents during the
% mitosis stage, and fix the tree.
% Maria Enokian
function ContextChangeParent(familyID,time,trackID)
    global CellTracks
    global Figures

    % This will prompt the user and ask for what Parent should be swapped.
    answer = inputdlg('Enter the node that needs to be swapped','Parent Swap',1,{num2str(trackID)});
    if(isempty(answer)),return,end;
    
    [localLabels, revLocalLabels] = UI.GetLocalTreeLabels(familyID);
    newTrackIDLocal = answer{1};
    newTrackID = UI.LocalToTrack(revLocalLabels, newTrackIDLocal);

%    newTrackID = str2double(newTrackID(1));
    % If there isn't a parent ID, will send error. Example: Root Node
    parentTrackID = CellTracks(trackID).parentTrack;
    if (isempty(parentTrackID))
        warndlg('This is the root node and will not be able to switch parents');
        return;
    else
        parentTrackIDLocal = UI.TrackToLocal(localLabels, parentTrackID);
    end
    
    % If the track doesn't exist it will send a warning.
    if ( isnan(newTrackID) || newTrackID > length(CellTracks) )
        warn = sprintf('Track %s does not exist, use "Remove from Tree" instead.',newTrackIDLocal);
        warndlg(warn);
        return;
    end
   % if the cell doesn't exist in the current frame it will send a warning.
    if(isempty(CellTracks(newTrackID).hulls))
        warn = sprintf('Track %s does not exist, cannot switch Parents',newTrackIDLocal);
        warndlg(warn);
        return
    end
    % if the cells are the same it will send a warning.
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
    % if the cell does not exist untill later on in the tree it will send a
    % warning message.
    if ( time < CellTracks(newTrackID).startTime )
        warn = sprintf('Cannot switch Parents from %s to %s, track %s does not exist until frame %d.',parentTrackIDLocal, newTrackIDLocal,newTrackIDLocal, CellTracks(newTrackID).startTime);
        warndlg(warn);
        return
    end

        % if all the errors are good it will prompt the Editor.ChangeParents
        % function as a replayable action.
        bErr = Editor.ReplayableEditAction(@Editor.ChangeParent,familyID,trackID, newTrackID, time);
        if ( bErr )
            return;
        end
        % if the swap is successful in the global Log stack it will display
        % the words 'Parents Swapped' in the action field
        Error.LogAction('Parents Swapped',parentTrackID,newTrackID);


    newTrackID = Hulls.GetTrackID(curHull);
    UI.DrawTree(CellTracks(newTrackID).familyID);
    UI.DrawCells();
end
