function OutputDebugErrorFile()
    global CONSTANTS Log
    
    errfile = [CONSTANTS.datasetName '_DBGERR_' num2str(length(Log)) '.mat'];
    Helper.SaveLEVerState(errfile);
end

