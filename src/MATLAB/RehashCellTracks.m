%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     Copyright 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%     This file is part of LEVer - the tool for stem cell lineaging. See
%     https://pantherfile.uwm.edu/cohena/www/LEVer.html for details
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

function RehashCellTracks(trackID, newStartTime)
%RehashedCellTracks(trackID,newStartTime) will rearange the hulls in the
%given track so that the newTime will hash correctly.
%The hulls are hashed so that the index into the cell array is time of hull
%subtract start time of track.  eg hash = time of hull -
%CellTracks(i).startTime
%
%If newStartTime == oldStartTime, only the endTime will change.  Good for
%removing all of the 0's at the end of the hulls list for a given track.
%
%***WARNING*** if oldStartTime < newStartTime and there are hulls within
%[oldStartTime newStartTime) THEY WILL BE REMOVED FROM THE TRACK!!!


global CellTracks CellHulls

if ( ~exist('newStartTime','var') )
    nzidx = find(CellTracks(trackID).hulls,1,'first');
%     newStartTime = CellTracks(trackID).startTime + nzidx - 1;
    newStartTime = CellHulls(CellTracks(trackID).hulls(nzidx)).time;
end

%clean out empty history first
indexOfLastHull = find(CellTracks(trackID).hulls,1,'last');
if(indexOfLastHull~=length(CellTracks(trackID).hulls))
    CellTracks(trackID).hulls = CellTracks(trackID).hulls(1:indexOfLastHull);
    CellTracks(trackID).endTime = CellHulls(CellTracks(trackID).hulls(end)).time;
end

oldhulls = CellTracks(trackID).hulls;

dif = CellTracks(trackID).startTime - newStartTime;

CellTracks(trackID).hulls = zeros(1,length(oldhulls)+dif);

oldStartIdx = max(-dif,0)+1;
oldEndIdx = length(oldhulls);
newStartIdx = max(dif,0)+1;
newEndIdx = newStartIdx + oldEndIdx - oldStartIdx;

CellTracks(trackID).hulls(newStartIdx:newEndIdx) = oldhulls(oldStartIdx:oldEndIdx);
CellTracks(trackID).startTime = newStartTime;
end
