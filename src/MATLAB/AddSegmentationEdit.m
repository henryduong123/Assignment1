function AddSegmentationEdit(addNewHulls, addChangedHulls)
    global SegmentationEdits
    
    if ( isempty(SegmentationEdits) )
        SegmentationEdits.newHulls = [];
        SegmentationEdits.changedHulls = [];
    end
    
    SegmentationEdits.newHulls = unique([SegmentationEdits.newHulls addNewHulls]);
    SegmentationEdits.changedHulls = unique([SegmentationEdits.changedHulls addChangedHulls]);
    
    UpdateSegmentationEditsMenu();
end