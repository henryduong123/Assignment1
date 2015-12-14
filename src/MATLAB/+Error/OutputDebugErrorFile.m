% OutputDebugErrorFile()
% Outputs ReplayEditActions to a file, this should allow for a complete
% reconstruction of an edit set from the original data.

function OutputDebugErrorFile()
    global Log ReplayEditActions
    
    errfile = [Metadata.GetDatasetName() '_DBGEDITS_' num2str(length(Log)) '.mat'];
    save(errfile, 'ReplayEditActions');
end

