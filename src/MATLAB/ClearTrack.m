% Function clears out all data for a deleted track.
function ClearTrack(trackID)
    global CellTracks
    
    % Get all field names dynamically and clear them
    strFieldNames = fieldnames(CellTracks);
    for i=1:length(strFieldNames)
        CellTracks(trackID).(strFieldNames{i}) = [];
    end
end