
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

function [iterations totalTime] = LinkTrees(families, stopTime)
    global CellFamilies CellTracks
    
    iterations = 0;
    
    rootTrackIDs = [CellFamilies(families).rootTrackID];
    
    % Use changelabel to try and extend tracks back to first frame
    newRootTracks = [];
    backTracks = rootTrackIDs([CellTracks(rootTrackIDs).startTime] ~= 1);
    for i=1:length(backTracks)
        newRootTracks = [newRootTracks linkTreeBack(backTracks(i))];
    end
    
    rootTrackIDs = unique(getRootTracks(union(rootTrackIDs,newRootTracks)));
    
    % Try to Push/reseg
    totalTime = 0;
    maxPushCount = 10;
    for i=1:maxPushCount
    	[assignExt findTime extTime] = Families.LinkTreesForward(rootTrackIDs, stopTime);
%         LogAction(['Tree inference step ' num2str(i)],[assignExt findTime extTime],[]);
        totalTime = totalTime + findTime + extTime;
        
        iterations = i;
        
        if ( assignExt == 0 )
            break;
        end
    end
    
%     LogAction('Completed Tree Inference', [i totalTime],[]);
end

function newroot = linkTreeBack(rootTrack)
    global CellTracks
    
    costMatrix = Tracker.GetCostMatrix();
    
    curTrack = rootTrack;
    while ( CellTracks(curTrack).startTime > 1 )
        curHull = CellTracks(curTrack).hulls(1);
        prevHulls = find(costMatrix(:,curHull) > 0);
        
        if ( isempty(prevHulls) )
            break;
        end
        
        [bestCost bestIdx] = min(costMatrix(prevHulls,curHull));
        prevTrack = Hulls.GetTrackID(prevHulls(bestIdx));
        
        Tracks.ChangeLabel(curTrack, prevTrack);
        curTrack = getRootTracks(prevTrack);
    end
    
    newroot = curTrack;
end

function rootTracks = getRootTracks(tracks)
    global CellTracks CellFamilies
    
    rootTracks = [];
    for i=1:length(tracks)
        if ( isempty(CellTracks(tracks(i)).startTime) )
            continue;
        end
        
        familyID = CellTracks(tracks(i)).familyID;
        rootTracks = [rootTracks CellFamilies(familyID).rootTrackID];
    end
end