%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     This file is part of LEVer.exe
%     (C) 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function AddHull(num)
global Figures CellHulls

if(num>6)
    msgbox('Please limit number of new cells to 6','Add Hull Limit','help');
    return
end

[hullID trackID] = GetClosestCell(1);
clickPt = get(gca,'CurrentPoint');

if ( ~CHullContainsPoint(clickPt(1,1:2), CellHulls(hullID)) )
    trackID = [];
end

if(~isempty(trackID))
    % Try to split the existing hull    
    if ( num < 2 )
        try
            set(Figures.tree.handle,'Pointer','watch');
            set(Figures.cells.handle,'Pointer','watch');
            [deleteCells replaceCell] = MergeSplitCells(clickPt(1,1:2));
            if ( isempty(replaceCell) )
                set(Figures.tree.handle,'Pointer','arrow');
                set(Figures.cells.handle,'Pointer','arrow');
                msgbox(['Unable to merge ' num2str(trackID) ' any further in this frame'],'Unable to Merge','help','modal');
                return;
            end
            History('Push');
        catch errorMessage
            try
                ErrorHandeling(['MergeHull(' num2str(clickPt(1,1:2)) ') -- ' errorMessage.message], errorMessage.stack);
                return
            catch errorMessage2
                 fprintf('%s',errorMessage2.message);
                return
            end
        end
        set(Figures.tree.handle,'Pointer','arrow');
        set(Figures.cells.handle,'Pointer','arrow');
        LogAction('Merged cells',[deleteCells replaceCell],replaceCell);
	else
        try
            newTracks = SplitHull(hullID,num);
            if(isempty(newTracks))
                msgbox(['Unable to split ' num2str(trackID) ' any further in this frame'],'Unable to Split','help','modal');
                return
            end
            History('Push');
        catch errorMessage
            try
                ErrorHandeling(['SplitHull(' num2str(hullID) ' ' num2str(num) ') -- ' errorMessage.message], errorMessage.stack);
                return
            catch errorMessage2
                 fprintf('%s',errorMessage2.message);
                return
            end
        end
        LogAction('Split cell',trackID,[trackID newTracks]);
    end
elseif ( num<2 )
    % Try to run local segmentation and find a hull we missed or place a
    % point-hull at least
    try
        newTrack = AddNewSegmentHull(clickPt(1,1:2));
        History('Push');
    catch errorMessage
        try
            ErrorHandeling(['AddNewSegmentHull(clickPt(1,1:2)) -- ' errorMessage.message], errorMessage.stack);
            return
        catch errorMessage2
            fprintf('%s',errorMessage2.message);
            return
        end
    end
    LogAction('Added cell',newTrack);
else
    return;
end

DrawTree(Figures.tree.familyID);
DrawCells();
end
