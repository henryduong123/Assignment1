function UpdateResegIndicators()
    global Figures ResegState
    
    if ( isempty(ResegState) || isempty(Figures.tree.resegIndicators) )
        return;
    end

    markerColor = 'r';
    
    newMarker = '.';
    resegTime = max(ResegState.currentTime-1,1);
    if ( Figures.time == resegTime )
        newMarker = 'o';
    end

    for i=1:length(Figures.tree.resegIndicators)
        set(Figures.tree.resegIndicators(i), 'Marker',newMarker, 'MarkerEdgeColor',markerColor);
    end
end