% droppedTracks = ChangeTrackID(currentTrack,desiredTracktime,time)
% if time==[] then the whole track will be renamed to the desiredTrack
% ChangeLabel will change the currentTrack to the desiredTrack's label.
% The list of tracks that have been removed from the tree due to this label
% change will be returned.

% ChangeLog
% EW 6/6/12 rewrite
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

function droppedTracks = ChangeTrackID(currentTrack,desiredTrack,time)
global CellTracks CellFamilies

droppedTracks = [];

if (isempty(currentTrack) || isempty(desiredTrack))
    error('Need both tracks, currentTrack: %d, desiredTrack: %d',currentTrack,desiredTrack);
end

if (time<CellTracks(desiredTrack).startTime)
    error('DesiredTrack %d has to exist prior to time %d',desiredTrack,time);
end

if ( currentTrack == desiredTrack )
    return;
end

if(~exist('time','var'))
    time = CellTracks(currentTrack).startTime;
end

% if (time>=CellTracks(desiredTrack).startTime)
    %% The desiredTrack is before the currentTrack
    % Remove any future track on the desiredTrack
    if (time<=CellTracks(desiredTrack).endTime)
        droppedTracks = [droppedTracks Families.RemoveFromTreePrune(desiredTrack,time)];
    end
    %Gather the hulls to move and leave the rest on the currentTrack
    startHash = time-CellTracks(currentTrack).startTime+1;
    if ( startHash <= 0 )
        startHash = 1;
    end
    
    endHash = length(CellTracks(currentTrack).hulls);
    hulls = CellTracks(currentTrack).hulls(startHash:endHash);
% else
%     %% The currentTrack is before the desiredTrack
%     % Remove any future track on the currentTrack
%     currentParent = CellTracks(currentTrack).parentTrack;
%     droppedTracks = [droppedTracks Families.RemoveFromTreePrune(currentTrack,time)];
%     hulls = CellTracks(currentTrack).hulls;
% end

if (any(droppedTracks==desiredTrack))
    % This means that the desired track is off the tree but still has all of
    % its hulls intact.  This needs to be cleared out for the currentTrack to
    % fill it
    tempHulls = CellTracks(desiredTrack).hulls;
    tempDropped = Tracks.RemoveHullFromTrack(tempHulls(1));
    newFam = Families.NewCellFamily(tempHulls(1));
    newTrack = CellFamilies(newFam).rootTrackID;
    
    for i=2:length(tempHulls)
        tempDropped = [tempDropped Tracks.RemoveHullFromTrack(tempHulls(i))];
        tempDropped = [tempDropped Tracks.AddHullToTrack(tempHulls(i),newTrack)];
    end
    if (length(tempDropped)==2)
        Families.ReconnectParentWithChildren(newTrack,tempDropped);
    end
    droppedTracks = [droppedTracks newTrack];
end

%% Move the hulls from the currentTrack to the desiredTrack
for i=1:length(hulls)
    droppedTracks = [droppedTracks Tracks.RemoveHullFromTrack(hulls(i))];
    droppedTracks = [droppedTracks Tracks.AddHullToTrack(hulls(i),desiredTrack)];
end

%% Clean up
% Clear out any empty tracks from the list
droppedTracks = droppedTracks(arrayfun(@(x)(~isempty(x.hulls)),CellTracks(droppedTracks)));
end
