% bLocked = CheckLocked(tracks)
%
% Check if tracks are on locked families, return list bLocked with boolean
% indicator per track.

function bLocked = CheckLocked(tracks)
    global CellTracks CellFamilies
    
    famIDs = [CellTracks(tracks).familyID];
    bLocked = ([CellFamilies(famIDs).bLocked] ~= 0);
end
