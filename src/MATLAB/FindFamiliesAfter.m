
% Find the set of families which start after the beginning of this track
function families = FindFamiliesAfter(trackID)
    global CellTracks CellFamilies
    
    nefam = find(arrayfun(@(x)(~isempty(x.startTime)), CellFamilies));
    
    families = nefam([CellFamilies(nefam).startTime] > CellTracks(trackID).startTime);
end