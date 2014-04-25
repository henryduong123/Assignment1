function FigureTreeDown(src,evnt, trackID)
    global Figures CellTracks
    
    if ( ~exist('trackID','var') )
        trackID = [];
    end
    
    if ( ~isempty(trackID) && strcmpi(Figures.cells.editMode, 'mitosis') )
        time = CellTracks(trackID).startTime;
        
        UI.MitosisSelectTrackingCell(trackID, time);
        return;
    end
    
    if(strcmp(get(Figures.tree.handle,'SelectionType'),'normal'))
        set(Figures.tree.handle, 'WindowButtonMotionFcn',@UI.FigureTreeDrag);
        
        UI.MoveLine();
    end
end
