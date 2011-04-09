function ContextChangeParent(trackID,time)
%Function for context menu call back

%--Eric Wait

global CellTracks

newParentID = inputdlg('Enter New Parent','New Parent',1,{num2str(CellTracks(trackID).parentTrack)});
if(isempty(newParentID)),return,end;
newParentID = str2double(newParentID(1));

%error checking
if(0>=newParentID || length(CellTracks)<newParentID || isempty(CellTracks(newParentID).hulls))
    msgbox(['Parent ' num2str(newParentID) ' is not a valid cell'],'Parent Change','warn');
    return
end
if(CellTracks(newParentID).startTime > time)
    msgbox(['Parent ' num2str(newParentID) ' comes after ' num2str(trackID) ' consider a different edit.'],'Parent Change','warn');
    return
elseif(CellTracks(trackID).endTime < CellTracks(newParentID).startTime)
    msgbox(['Sibling ' num2str(trackID) ' exists completely before ' num2str(newParentID) ' consider a rename instead.'],'Parent Change','warn');
    return
end

oldParent = CellTracks(trackID).parentTrack;
ChangeTrackParent(newParentID,time,trackID);

History('Push');
LogAction(['Changed parent of ' num2str(trackID)],oldParent,newParentID);

DrawTree(CellTracks(newParentID).familyID);
DrawCells();
end
