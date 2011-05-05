%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     This file is part of LEVer.exe
%     (C) 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Function clears out all data for a deleted track.
function ClearTrack(trackID)
    global CellTracks
    
    % Get all field names dynamically and clear them
    strFieldNames = fieldnames(CellTracks);
    for i=1:length(strFieldNames)
        CellTracks(trackID).(strFieldNames{i}) = [];
    end
end