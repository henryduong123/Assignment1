function colorStruct = GetCellDrawProps(trackID, hullID, drawString)
    global Figures CellTracks
    
    [fontSize shapeSize] = UI.GetFontShapeSizes(length(drawString));
    
    colorStruct = struct('text',{[0 0 0]}, 'textBack', {'none'}, ...
                         'back', {[0.5 0.5 0.5]}, 'edge', {[0.5 0.5 0.5]}, ...
                         'edgeWidth', {1}, 'edgeStyle', {'-'}, ...
                         'fontSize', {fontSize}, 'fontWeight', {'normal'}, ...
                         'shape', {'square'}, 'shapeSize', {shapeSize});
	
	bDrawOffTree = strcmp(get(Figures.cells.menuHandles.treeLabelsOn, 'Checked'),'on');
	
    if (HighlightTrack(trackID))
        colorStruct.back = CellTracks(trackID).color.background;
        colorStruct.edge = CellTracks(trackID).color.background;
        colorStruct.text = CellTracks(trackID).color.text;
        colorStruct.fontWeight = 'bold';
        colorStruct.shape = 'o';
    elseif ( bDrawOffTree )
        colorStruct.back = CellTracks(trackID).color.backgroundDark;
        colorStruct.edge = CellTracks(trackID).color.backgroundDark;
        colorStruct.text = CellTracks(trackID).color.text * 0.5;
        colorStruct.fontSize = colorStruct.fontSize * 0.9;
    end
    
    if ( ~isempty(Tracks.GetTimeOfDeath(trackID)) )
        colorStruct.back = 'k';
        colorStruct.edge = 'r';
        colorStruct.text = 'r';
    end
    
    if ( Figures.cells.showInterior )
        colorStruct.textBack = colorStruct.back;
    end
    
    if ( any(Figures.cells.selectedHulls == hullID) )
        colorStruct.edgeWidth = 1.5;
        colorStruct.edgeStyle = '--';
    end
end

function bHighlight = HighlightTrack(trackID)
    global Figures CellTracks CellFamilies
    
    bHighlight = 0;
    
    if ( Figures.tree.familyID == CellTracks(trackID).familyID )
        bHighlight = 1;
    elseif isfield(CellFamilies, 'extFamily')
        family = CellFamilies(Figures.tree.familyID);
        bHighlight = find( family.extFamily == CellTracks(trackID).familyID );
    end
end