function bGreatOrEqual = CheckFileVersionString(minVersion)
    global CONSTANTS
    
    bGreatOrEqual = 0;
    
    if ( ~isfield(CONSTANTS,'version') )
        return;
    end
    
    % Sorts entries, if CONSTANTS.version is >= minVersion, then order will start with entry 1.
    [dump,order] = sort({minVersion,CONSTANTS.version}, 'first');
    
    if ( order(1) ~= 1 )
        return;
    end
    
    bGreatOrEqual = 1;
end