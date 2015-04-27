% [historyAction deletedCells replaceCell] = MergeCellsAction(selectedHulls)
% Edit Action:
% 
% Attempt to merge oversegmented cells.

function [historyAction deletedCells replaceCell] = MergeCellsAction(selectedHulls, selectedTree)
    global SegmentationEdits
    
    historyAction = '';
    
    [deletedCells replaceCell] = Segmentation.MergeSplitCells(selectedHulls, selectedTree);
    
    if ( isempty(replaceCell) )
        return;
    end

    SegmentationEdits.newHulls = [];
    SegmentationEdits.changedHulls = [];
    
    UI.UpdateSegmentationEditsMenu();
    
    historyAction = 'Push';
end
