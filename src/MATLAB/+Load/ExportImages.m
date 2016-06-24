function jsonPath = ExportImages(exportDir, inRoot,inFilename)
    [~,imD] = MicroscopeData.Original.Convert2Tiffs(inRoot,inFilename, exportDir, true, false);
    if ( length(imD) > 1 )
        [~,imName] = fileparts(inFilename);
        exportDir = fullfile(exportDir,imName);
    end
    
    [~,chkIdx] = max(cellfun(@(x)((x.NumberOfFrames)),imD));
    jsonPath = fullfile(exportDir,imD{chkIdx}.DatasetName,[imD{chkIdx}.DatasetName '.json']);
end
