% [deletedCells replaceCell] = MergeCells(selectedHulls)
% Edit Action:
% Attempt to merge oversegmented cells.

function [deletedCells replaceCell] = MergeCells(selectedHulls)
    global SegmentationEdits
    
    [deletedCells replaceCell] = Segmentation.MergeSplitCells(selectedHulls);
    
    if ( isempty(replaceCell) )
        return;
    end

    SegmentationEdits.newHulls = [];
    SegmentationEdits.changedHulls = [];
    
    UI.UpdateSegmentationEditsMenu();
    Families.ProcessNewborns();
end