% MoveMitosisDown(time,trackID) will move the Mitosis even down the track
% to the given time.  The hulls from the children between parent mitosis
% and the given time are broken off into thier own tracks.

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

function MoveMitosisDown(time,trackID)

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