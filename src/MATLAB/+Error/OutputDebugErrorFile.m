% OutputDebugErrorFile()
% Outputs ReplayEditActions to a file, this should allow for a complete
% reconstruction of an edit set from the original data.

function OutputDebugErrorFile()
    global CONSTANTS Log ReplayEditActions
    
    errfile = [CONSTANTS.datasetName '_DBGEDITS_' num2str(length(Log)) '.mat'];
    save(errfile, 'ReplayEditActions');
end

