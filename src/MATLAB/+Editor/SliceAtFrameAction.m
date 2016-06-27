% historyAction = SliceAtFrameAction(rootTrackID, time)
% Edit Action:
%
% Call RemoveFromTree() on all tracks on family at time.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     Copyright 2011-2016 Andrew Cohen
%
%     This file is part of LEVer - the tool for stem cell lineaging. See
%     http://n2t.net/ark:/87918/d9rp4t for details
% 
%     LEVer is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
%     LEVer is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
% 
%     You should have received a copy of the GNU General Public License
%     along with LEVer in file "gnu gpl v3.txt".  If not, see 
%     <http://www.gnu.org/licenses/>.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function historyAction = SliceAtFrameAction(rootTrackID, time)
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
