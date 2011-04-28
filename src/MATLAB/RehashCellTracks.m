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

%--Eric Wait

global CellTracks CellHulls

if ( ~exist('newStartTime','var') )
    nzidx = find(CellTracks(trackID).hulls,1,'first');
    newStartTime = CellTracks(trackID).startTime + nzidx - 1;
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
