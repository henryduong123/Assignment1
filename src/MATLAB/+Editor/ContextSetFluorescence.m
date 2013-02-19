% historyAction = ContextSetFluorescence(trackID, fluorType, bActive)
% Edit Action:
% 
% Sets or clears the fluorescence type for the given track at the current
% time.

function historyAction = ContextSetFluorescence(trackID, fluorType, bActive)
    global CellTracks Figures
    
    idx = find(CellTracks(trackID).fluorTimes(1,:) == Figures.time);
    if (isempty(idx))
        return
    end
    
    if (bActive)
        CellTracks(trackID).fluorTimes(2,idx) = 0;
        CellTracks(trackID).markerTimes(2,idx) = 0;
    else
        CellTracks(trackID).fluorTimes(2,idx) = fluorType;
        CellTracks(trackID).markerTimes(2,idx) = fluorType;
    end
    
    historyAction = 'Push';
end