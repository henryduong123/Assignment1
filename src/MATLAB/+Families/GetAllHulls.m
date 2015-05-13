function [hullIDs missingHulls] = GetAllHulls(familyID)
    global CellFamilies CellTracks
    
    famTracks = CellFamilies(familyID).tracks;
    famHulls = [CellTracks(famTracks).hulls];
    
    hullIDs = famHulls(famHulls > 0);
    missingHulls = nnz(famHulls == 0);
end