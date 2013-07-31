% FigureCellUp(src,evnt)

% ChangeLog:
% NLS 6/11/12 Created

function FigureCellUp(src,evnt)
global Figures CellTracks MitDragCoords

bWasDragging = false;
if ( Helper.NonEmptyField(Figures.cells, 'dragElements') )
    structfun(@(x)(delete(x)), Figures.cells.dragElements);
    Figures.cells.dragElements = [];
    
    bWasDragging = true;
end

set(Figures.cells.handle,'WindowButtonUpFcn','');
set(Figures.cells.handle,'WindowButtonMotionFcn',@(src,evt)(1))

if ( strcmpi(Figures.cells.editMode, 'mitosis') )
    % Find new Mitosis cells and parent
    dragDistSq = sum((MitDragCoords(:,1)-MitDragCoords(:,2)).^2);
    if ( dragDistSq > (7)^2 )
        addMitosisEvent(Figures.tree.familyID, Figures.time, MitDragCoords);
        
        UI.DrawTree(Figures.tree.familyID);
        UI.DrawCells();
    end
    
    clear global MitDragCoords;
    return;
end

if(Figures.cells.downHullID == -1)
    return
end

if ( ~bWasDragging )
    currentHullID = Figures.cells.downHullID;
else
    currentHullID = Hulls.FindHull(Figures.time, get(gca,'CurrentPoint'));
end

if ( currentHullID == -1 )
    currentHullID = Figures.cells.downHullID;
end
previousTrackID = Hulls.GetTrackID(Figures.cells.downHullID);

if(currentHullID~=Figures.cells.downHullID)
    trackID = Hulls.GetTrackID(currentHullID);
    
    bErr = Editor.ReplayableEditAction(@Editor.ContextSwapLabels, trackID, previousTrackID, Figures.time);
    if ( bErr )
        return;
    end
    
    Error.LogAction(['Swapped tracks ' num2str(trackID) ', ' num2str(previousTrackID) ' beginning at t=' num2str(Figures.time)], [],[]);
    
    previousTrackID = Hulls.GetTrackID(currentHullID);
    
    UI.DrawTree(CellTracks(previousTrackID).familyID);
elseif(CellTracks(previousTrackID).familyID~=Figures.tree.familyID)
    %no change and the current tree contains the cell clicked on
    UI.DrawTree(CellTracks(previousTrackID).familyID);
end


UI.DrawCells();
end

function addMitosisEvent(treeID, time, dragCoords)
    global CellTracks CellFamilies
    % Find new Mitosis cells and parent
    
    if ( time < 2 )
        msgbox('Cannot create mitosis event in first frame','Invalid Mitosis','warn');
        return
    end
    
    treeTracks = [CellFamilies(treeID).tracks];
    
    bInTracks = Helper.CheckInTracks(time, treeTracks, 0, 0);
	checkTracks = treeTracks(bInTracks);
    if ( isempty(checkTracks) )
        msgbox('No valid tracks to add a mitosis onto','Invalid Mitosis','warn');
        return;
    end
    
    startTimes = [CellTracks(checkTracks).startTime];
    [minTime minIdx] = min(startTimes);

    % TODO: make this deal with 
%     % If a mitosis is specified RIGHT after another one, we have a problem
%     if ( minTime == time-1 )
%         mitHull = CellTracks(checkTracks(minIdx)).hulls(1);
%         msgbox('No valid tracks to add a mitosis onto','Invalid Mitosis','warning');
%         return;
%     end
    
    Editor.ReplayableEditAction(@Editor.CreateMitosisAction, treeID, time, (dragCoords.'));
    
end

