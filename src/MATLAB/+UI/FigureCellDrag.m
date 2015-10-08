
function FigureCellDrag(src,evnt)
    global Figures
    
    currentPoint = get(gca,'CurrentPoint');
    
    if ( strcmpi(Figures.cells.editMode, 'mitosis') )
        if ( ~Helper.NonEmptyField(Figures.cells, 'dragElements') )
            return;
        end
        
        updateMitosisDrag(currentPoint)
        return;
    end
    
    if ( ~Helper.NonEmptyField(Figures.cells, 'dragElements') )
        createNormalDragElements(Figures.cells.downHullID, currentPoint)
    elseif ( ishandle(Figures.cells.dragElements.bgLabel) )
        set(Figures.cells.dragElements.bgLabel, 'XData',currentPoint(1,1));
        set(Figures.cells.dragElements.bgLabel, 'YData',currentPoint(1,2));
        set(Figures.cells.dragElements.label, 'Position',currentPoint(1,1:2));
    else
        Figures.cells.dragElements = [];
        set(Figures.cells.handle, 'WindowButtonMotionFcn','');
    end
end

function updateMitosisDrag(currentPoint)
    global Figures MitDragCoords
    
    MitDragCoords(:,2) = currentPoint(1,1:2).';
    
    set(Figures.cells.dragElements.line, 'XData',MitDragCoords(1,:));
    set(Figures.cells.dragElements.line, 'YData',MitDragCoords(2,:));
end

function createNormalDragElements(hullID, currentPoint)
    global Figures

    curAx = get(Figures.cells.handle, 'CurrentAxes');
    
    trackID = Hulls.GetTrackID(hullID);
    [localLabels, ~] = UI.GetLocalTreeLabels(Figures.tree.familyID);
    trackIDLocal = UI.TrackToLocal(localLabels,trackID);

    xCoord = currentPoint(1,1);
    yCoord = currentPoint(1,2);

    if(Figures.cells.showInterior)
        drawString = [trackIDLocal ' / ' num2str(hullID)];
    else
        drawString = trackIDLocal;
    end
    
    colorStruct = UI.GetCellDrawProps(trackID, hullID, drawString);
    
    [textHandle bgHandle] = UI.DrawCellLabel(curAx, drawString, xCoord, yCoord, colorStruct);
    
    set(textHandle, 'HitTest','off');
    set(bgHandle, 'HitTest','off');

    Figures.cells.dragElements.bgLabel = bgHandle;
    Figures.cells.dragElements.label = textHandle;
end
