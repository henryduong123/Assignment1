function ContextChangeParent(trackID)
%Function for context menu call back
global CellTracks

newParentID = inputdlg('Enter New Parent','New Parent',1,{num2str(CellTracks(trackID).parentTrack)});
if(isempty(newParentID)),return,end;
newParentID = str2double(newParentID(1));

if(CellTracks(newParentID).startTime > CellTracks(trackID).startTime)
    msgbox(['Parent ' num2str(newParentID) ' comes after ' num2str(trackID) ' consider a different edit.'],'Parent Change','warn');
    return
elseif(CellTracks(trackID).endTime < CellTracks(newParentID).startTime)
    msgbox(['Sibling ' num2str(trackID) ' exists completely before ' num2str(newParentID) ' consider a rename instead.'],'Parent Change','warn');
    return
end

oldParent = CellTracks(trackID).parentTrack;
ChangeTrackParent(newParentID,CellTracks(trackID).startTime,trackID);

History('Push');
LogAction(['Changed parent of ' num2str(trackID)],oldParent,newParentID);

DrawTree(CellTracks(trackID).familyID);
DrawCells();
end
