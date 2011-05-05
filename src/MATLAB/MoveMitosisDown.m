%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     This file is part of LEVer.exe
%     (C) 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function MoveMitosisDown(time,trackID)
% MoveMitosisDown(time,trackID) will move the Mitosis even down the track
% to the given time.  The hulls from the children between parent mitosis
% and the given time are broken off into thier own tracks.


global CellTracks CellFamilies

remove = 0;
children = {};

for i=1:length(CellTracks(trackID).childrenTracks)
    if(CellTracks(CellTracks(trackID).childrenTracks(i)).endTime <= time)
        remove = 1;
        break
    end
    hash = time - CellTracks(CellTracks(trackID).childrenTracks(i)).startTime + 1;
    if(0<hash)
        children(i).startTime = CellTracks(CellTracks(trackID).childrenTracks(i)).startTime;
        children(i).hulls = CellTracks(CellTracks(trackID).childrenTracks(i)).hulls(1:hash);
    end
end

if(remove)
    RemoveChildren(trackID);
else
    for i=1:length(children)
        familyID = NewCellFamily(children(i).hulls(1),children(i).startTime);
        newTrackID = CellFamilies(familyID).rootTrackID;
        for j=2:length(children(i).hulls)
            if(children(i).hulls(j)~=0)
                AddHullToTrack(children(i).hulls(j),newTrackID,[]);
            end
        end
    end
end
end