function ContextChangeLabel(time,trackID)
%context menu callback function

%--Eric Wait

global CellTracks HashedCells

newTrackID = inputdlg('Enter New Label','New Label',1,{num2str(trackID)});
if(isempty(newTrackID)),return,end;
newTrackID = str2double(newTrackID(1));

%error checking
if(0>=newTrackID)
    msgbox(['New label of ' num2str(newTrackID) ' is not a valid number'],'Change Label','warn');
    return
elseif(length(CellTracks)<newTrackID || isempty(CellTracks(newTrackID).hulls))
    choice = questdlg(['Changing ' num2str(trackID) ' to ' num2str(newTrackID) ' will have the same effect as Remove From Tree'],...
        'Remove From Tree?','Continue','Cancel','Cancel');
    switch choice
        case 'Continue'
            newLabel = length(CellTracks) + 1;
            ContextRemoveFromTree(time,trackID);
            msgbox(['The new cell label is ' num2str(newLabel)],'Remove From Tree','help');
            return
        case 'Cancel'
            return
    end
elseif(newTrackID>length(CellTracks) || isempty(CellTracks(newTrackID).hulls))
    choice = questdlg('New label does not exist. Do you want this cell and its children dropped from its tree?',...
        'Drop Cell?','Yes','Cancel','Cancel');
    switch choice
        case 'Yes'
            oldFamily = CellTracks(trackID).familyID;
            RemoveFromTree(time,trackID,'yes');
            History('Push');
            LogAction(['Removed ' num2str(trackID) ' From Tree'], oldFamily,CellTracks(trackID).familyID);
        case 'Cancel'
            return
    end
elseif(~isempty(find([HashedCells{time}.trackID]==newTrackID,1)))
        choice = questdlg(['Label ' num2str(newTrackID) ' exist on this frame. Would you like these labels to swap from here forward or just this frame?'],...
            'Swap Labels?','Forward','This Frame','Cancel','Cancel');
    switch choice
        case 'Forward'
            SwapTrackLabels(time,trackID,newTrackID);
            History('Push');
            LogAction('Swapped Labels',trackID,newTrackID);
        case 'This Frame'
            SwapHulls(time,trackID,newTrackID);
        case 'Cancel'
            return
    end
elseif(isempty(CellTracks(trackID).parentTrack) && isempty(CellTracks(trackID).childrenTracks) && 1==length(CellTracks(trackID).hulls))
    hullID = CellTracks(trackID).hulls(1);
    AddSingleHullToTrack(trackID,newTrackID);
    History('Push');
    LogAction('Added hull to track',hullID,newTrackID);
elseif(~isempty(CellTracks(trackID).parentTrack) && CellTracks(trackID).parentTrack==newTrackID)
    MoveMitosisUp(time,trackID)
    History('Push');
    LogAction('Moved Mitosis Up',trackID,newTrackID);
elseif(~isempty(CellTracks(newTrackID).parentTrack) &&CellTracks(newTrackID).parentTrack==trackID)
    MoveMitosisUp(time,newTrackID)
    History('Push');
    LogAction('Moved Mitosis Up',newTrackID,trackID);
else
    ChangeLabel(time,trackID,newTrackID);
    History('Push');
    LogAction('ChangeLabel',trackID,newTrackID);
end

DrawTree(CellTracks(newTrackID).familyID);
DrawCells();
end
