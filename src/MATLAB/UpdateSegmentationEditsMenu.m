function UpdateSegmentationEditsMenu()
    global SegmentationEdits Figures
    
    if ( isempty(SegmentationEdits) || isempty(SegmentationEdits.newHulls) || isempty(SegmentationEdits.changedHulls) )
        set(Figures.tree.menuHandles.learnEditsMenu, 'enable', 'off');
        set(Figures.cells.menuHandles.learnEditsMenu, 'enable', 'off');
    else
        set(Figures.tree.menuHandles.learnEditsMenu, 'enable', 'on');
        set(Figures.cells.menuHandles.learnEditsMenu, 'enable', 'on');
    end
end