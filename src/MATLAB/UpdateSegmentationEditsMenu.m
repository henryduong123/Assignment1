function UpdateSegmentationEditsMenu(src,evnt)
    global SegmentationEdits Figures
    
    if ( isempty(SegmentationEdits) || isempty(SegmentationEdits.newHulls) || isempty(SegmentationEdits.changedHulls) )
%         set(Figures.tree.menuHandles.learnEditsMenu, 'enable', 'off');
%         set(Figures.cells.menuHandles.learnEditsMenu, 'enable', 'off');
        set(Figures.cells.learnButton, 'Visible', 'off');
    else
        pos = get(Figures.cells.handle,'Position');
        position = [pos(3)-120 pos(4)-30 100 20];
        set(Figures.cells.learnButton, 'Visible', 'on','Position',position);
        %         set(Figures.tree.menuHandles.learnEditsMenu, 'enable', 'on');
        %         set(Figures.cells.menuHandles.learnEditsMenu, 'enable', 'on');
    end
end