function ChangeTrackParent(parentTrackID,time,childTrackID)
%ChangeTrackParent(parentTrackID,time,childTrackID) will take the
%childTrack and connect it to the parent track.  It also takes the hulls
%that exist in the parent track that are come after the childTrack root and
%makes a new track with said hulls.  When finished there should be a new
%track and the child track that are siblings with the parent track being
%the parent.

%--Eric Wait

global CellTracks CellFamilies

%see if the child exists before time
if(time > CellTracks(childTrackID).startTime)
    newFamilyID = RemoveFromTree(time,childTrackID,'yes');
    childTrackID = CellFamilies(newFamilyID).rootTrackID;
end

%find where the child should attach to the parent
hash = time - CellTracks(parentTrackID).startTime + 1;
if(hash <= 0)
    error('Trying to attach a parent that comes after the child');
elseif(hash <= length(CellTracks(parentTrackID).hulls))
    parentHullID = CellTracks(parentTrackID).hulls(hash);
    siblingTrackID = SplitTrack(parentTrackID,parentHullID); % SplitTrack adds sibling to the parent already
else
    %just rename the child to the parent
    ChangeLabel(time,childTrackID,parentTrackID);
    return
end

oldFamilyID = CellTracks(childTrackID).familyID;
newFamilyID = CellTracks(siblingTrackID).familyID;

childIndex = length(CellTracks(parentTrackID).childrenTracks) + 1;
CellTracks(parentTrackID).childrenTracks(childIndex) = childTrackID;

%clean up old parent
if(~isempty(CellTracks(childTrackID).siblingTrack))
    CellTracks(CellTracks(childTrackID).siblingTrack).siblingTrack = [];
    CombineTrackWithParent(CellTracks(childTrackID).siblingTrack);
%     ChangeLabel(CellTracks(CellTracks(childTrackID).siblingTrack).startTime,...
%         CellTracks(childTrackID).siblingTrack,CellTracks(childTrackID).parentTrack);
%     index = CellTracks(CellTracks(childTrackID).parentTrack).childrenTracks == childTrackID;
%     CellTracks(CellTracks(childTrackID).parentTrack).childrenTracks(index) = [];
end
CellTracks(childTrackID).parentTrack = parentTrackID;

%Detatch childTrack and clean up child's family
if(oldFamilyID~=newFamilyID)
    ChangeTrackAndChildrensFamily(oldFamilyID,newFamilyID,childTrackID);
end

CellTracks(childTrackID).siblingTrack = siblingTrackID;
CellTracks(siblingTrackID).siblingTrack = childTrackID;

end
