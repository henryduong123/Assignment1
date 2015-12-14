function datasetName = GetDatasetName()
    global CONSTANTS
    
    datasetName = '';
    if ( ~isfield(CONSTANTS,'imageData') )
        return;
    end
    
    datasetName = CONSTANTS.imageData.DatasetName;
end
