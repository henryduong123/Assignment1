function ContextChangeLabel(time,trackID)
%context menu callback function
global CellTracks HashedCells

newTrackID = inputdlg('Enter New Label','New Label',1,{num2str(trackID)});
if(isempty(newTrackID)),return,end;
newTrackID = str2double(newTrackID(1));

if(newTrackID>length(CellTracks) || isempty(CellTracks(newTrackID).hulls))
    choice = questdlg('New label does not exist. Do you want this cell and its children dropped from its tree?','Drop Cell?','Yes','Cancel','Cancel');
    switch choice
        case 'Yes'
            oldFamily = CellTracks(trackID).familyID;
            RemoveFromTree(time,trackID);
            History('Push');
            LogAction(['Removed ' num2str(trackID) ' From Tree'], oldFamily,CellTracks(trackID).familyID);
        case 'Cancel'
            return
    end
elseif(~isempty(find([HashedCells{time}.trackID]==newTrackID,1)))
        choice = questdlg(['Label ' num2str(newTrackID) ' exist on this frame. Would you like these labels to swap from here forward?'],...
            'Swap Labels?','Yes','Cancel','Cancel');
    switch choice
        case 'Yes'
            SwapTrackLabels(time,trackID,newTrackID);
            History('Push');
            LogAction('Swapped Labels',trackID,newTrackID);
        case 'Cancel'
            return
    end
else
    ChangeLabel(time,trackID,newTrackID);
    History('Push');
    LogAction('ChangeLabel',trackID,newTrackID);
end

DrawTree(CellTracks(newTrackID).familyID);
DrawCells();
end
