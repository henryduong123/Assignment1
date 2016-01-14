function roots = GetFamilyRoots(rootTrackID)
    global CellFamilies CellTracks
    
    familyID = CellTracks(rootTrackID).familyID;
    family = CellFamilies(familyID);
    if (isfield(CellFamilies, 'extFamily') && ~isempty(family.extFamily))
        roots = [CellFamilies(family.extFamily).rootTrackID];
    else
        roots = CellFamilies(familyID).rootTrackID;
    end
    
    rootFamilies = [CellTracks(roots).familyID];
    numTracks = arrayfun(@(x)(length(x.tracks)),CellFamilies(rootFamilies));

    [~,srtIdx] = sort(numTracks,'descend');
    roots = roots(srtIdx);
end
