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

dif = CellTracks(trackID).startTime - newStartTime;

if(0<dif)
    for i=length(CellTracks(trackID).hulls):-1:1
        CellTracks(trackID).hulls(i+dif) = CellTracks(trackID).hulls(i);
    end
    for i=1:dif
        CellTracks(trackID).hulls(i) = 0;
    end
elseif(0>dif)
    oldLength = length(CellTracks(trackID).hulls);
    for i=1-dif:length(CellTracks(trackID).hulls)
        CellTracks(trackID).hulls(i+dif) = CellTracks(trackID).hulls(i);
    end
    for i=length(CellTracks(trackID).hulls):-1:oldLength
        CellTracks(trackID).hulls(i) = 0;
    end
end

%clean out any old history
indexOfLastHull = find(CellTracks(trackID).hulls,1,'last');
if(indexOfLastHull~=length(CellTracks(trackID).hulls))
    CellTracks(trackID).hulls = CellTracks(trackID).hulls(1:indexOfLastHull);
    CellTracks(trackID).endTime = CellHulls(CellTracks(trackID).hulls(end)).time;
end

CellTracks(trackID).startTime = newStartTime;

%check to see if this effects the family
end
