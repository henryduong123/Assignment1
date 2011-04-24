function RemoveSegmentationEdit(rmHull)
    global SegmentationEdits
    
    % Remove the deleted hull from the edited segmentations lists
    SegmentationEdits.newHulls(SegmentationEdits.newHulls == rmHull) = [];
    SegmentationEdits.changedHulls(SegmentationEdits.changedHulls == rmHull) = [];
    
    UpdateSegmentationEditsMenu();
end