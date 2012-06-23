% [historyAction deletedCells replaceCell] = MergeCells(selectedHulls)
% Edit Action:
% 
% Attempt to merge oversegmented cells.

function [historyAction deletedCells replaceCell] = MergeCells(selectedHulls)
    global SegmentationEdits
    
    historyAction = '';
    
    [deletedCells replaceCell] = Segmentation.MergeSplitCells(selectedHulls);
    
    if ( isempty(replaceCell) )
        return;
    end

    SegmentationEdits.newHulls = [];
    SegmentationEdits.changedHulls = [];
    
    UI.UpdateSegmentationEditsMenu();
    Families.ProcessNewborns();
    
    historyAction = 'Push';
end
