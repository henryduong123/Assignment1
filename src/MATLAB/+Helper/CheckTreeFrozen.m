% bFrozen = CheckTreeFrozen(tracks)
%
% Check if tracks are on frozen families, return list bFrozen with boolean
% indicator per track.

function bFrozen = CheckTreeFrozen(tracks)
    global CellTracks CellFamilies
    
    famIDs = [CellTracks(tracks).familyID];
    bFrozen = ([CellFamilies(famIDs).bFrozen] ~= 0);
end