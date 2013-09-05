% historyAction = SliceAtFrame(rootTrackID, time)
% Edit Action:
%
% Call RemoveFromTree() on all tracks on family at time.

function historyAction = SliceAtFrame(rootTrackID, time)
    global CellFamilies CellTracks
    
    familyID = CellTracks(rootTrackID).familyID;
    trackList = CellFamilies(familyID).tracks;
    
    startTimes = [CellTracks(trackList).startTime];
    endTimes = [CellTracks(trackList).endTime];
    
    inTracks = trackList((startTimes <= time) & (endTimes >= time));
    
    while ( ~isempty(inTracks) )
        droppedTracks = Families.RemoveFromTreePrune(inTracks(1), time);
        inTracks = setdiff(inTracks, [inTracks(1) droppedTracks]);
    end
    
    historyAction = 'Push';
end
