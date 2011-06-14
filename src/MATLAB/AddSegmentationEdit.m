%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     This file is part of LEVer.exe
%     (C) 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function AddSegmentationEdit(addNewHulls, addChangedHulls)
    global SegmentationEdits
    
    if ( isempty(SegmentationEdits) )
        SegmentationEdits.newHulls = [];
        SegmentationEdits.changedHulls = [];
        SegmentationEdits.maxEditedFrame = 1;
    end
    
    SegmentationEdits.newHulls = unique([SegmentationEdits.newHulls addNewHulls]);
    SegmentationEdits.changedHulls = unique([SegmentationEdits.changedHulls addChangedHulls]);
    SegmentationEdits.maxEditedFrame = max([SegmentationEdits.maxEditedFrame getFrameTimes(addNewHulls)]);
    
    UpdateSegmentationEditsMenu();
end

function times = getFrameTimes(hulls)
    global CellHulls
    
    times =[CellHulls(hulls).time];
end