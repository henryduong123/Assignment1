function roots = GetFamilyRoots(rootTrackID)
    global CellFamilies CellTracks
    
    roots = [];
    if isfield(CellFamilies, 'extFamily')
        familyID = CellTracks(rootTrackID).familyID;
        family = CellFamilies(familyID);
        if isempty(family.extFamily)
            roots = rootTrackID;
        else
            roots = [CellFamilies(family.extFamily).rootTrackID];
        end
    else
        roots = rootTrackID;
    end
end
