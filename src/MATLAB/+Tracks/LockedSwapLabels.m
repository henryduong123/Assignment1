% LockedSwapLabels(trackA, trackB, time)
%
% This function will swap the hulls of the two tracks at the given time.
% By it's nature this preserves structures because nothing but hull
% associations are modified.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     Copyright 2016 Drexel University
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


function LockedSwapLabels(trackA, trackB, time)

    %% Error Check
    hullA = Tracks.GetHullID(time, trackA);
    hullB = Tracks.GetHullID(time, trackB);
    if ( hullA == 0 )
        error('Track %d has no hull to swap at time %d,', trackA, time);
    end

    if ( hullB == 0 )
        error('Track %d has no hull to swap at time %d,', trackB, time);
    end

    swapTracking(hullA, hullB);
end

% swapTracking(hullA, hullB)
%
% Currently hullA has trackA, hullB has trackB
% swap so that (hullA -> trackB) and (hullB -> trackA)
function swapTracking(hullA, hullB)
    global CellHulls HashedCells CellTracks
    
    t = CellHulls(hullA).time;
    
    if ( t ~= CellHulls(hullB).time )
        error('Attempt to swap tracking information for hulls in different frames!');
    end
    
    trackA = Hulls.GetTrackID(hullA);
    trackB = Hulls.GetTrackID(hullB);
    
    hashAIdx = ([HashedCells{t}.hullID] == hullA);
    hashBIdx = ([HashedCells{t}.hullID] == hullB);
    
    % Swap hashed track IDs
    HashedCells{t}(hashAIdx).trackID = trackB;
    HashedCells{t}(hashBIdx).trackID = trackA;
    
    % Swap hulls in tracks
    hashTime = t - CellTracks(trackA).startTime + 1;
    CellTracks(trackA).hulls(hashTime) = hullB;
    
    hashTime = t - CellTracks(trackB).startTime + 1;
    CellTracks(trackB).hulls(hashTime) = hullA;
end
