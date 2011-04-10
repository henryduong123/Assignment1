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
    try
        newTracks = SplitHull(hullID,num);
        if(isempty(newTracks))
            msgbox(['Unable to split ' num2str(trackID) ' any further in this frame'],'Unable to Split','help','modal');
            return
        end
        History('Push');
    catch errorMessage
        try
            ErrorHandeling(['SplitHull(' num2str(hullID) ' ' num2str(num+1) ') -- ' errorMessage.message]);
            return
        catch errorMessage2
            fprintf(errorMessage2.message);
            return
        end
    end
    LogAction('Split cell',trackID,[trackID newTracks]);
elseif ( num<2 )
    % Try to run local segmentation and find a hull we missed or place a
    % point-hull at least
    try
        newTrack = AddNewSegmentHull(clickPt(1,1:2));
        History('Push');
    catch errorMessage
        try
            ErrorHandeling(['AddNewSegmentHull(clickPt(1,1:2)) -- ' errorMessage.message]);
            return
        catch errorMessage2
            fprintf(errorMessage2.message);
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