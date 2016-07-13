% changedHulls = AssignEdge(trackHull, assignHull)
% 
% Assign the edge from trackHull to assignHull, this changes the track
% assignment for assignHull such that it will be on the same track as
% trackHull.

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


function changedHulls = AssignEdge(trackHull, assignHull)
    global CellHulls CellTracks CellFamilies
    
    changedHulls = [];
    
     % Get track to which we will assign hull from trackHull
    track = Hulls.GetTrackID(trackHull);
    
    assignTime = CellHulls(assignHull).time;
    trackTime = CellHulls(trackHull).time;
    
    oldTrackHull = Tracks.GetHullID(assignTime, track);
    oldAssignTrack = Hulls.GetTrackID(assignHull);
    
    dir = sign(assignTime - trackTime);
    
    % Hull - track assignment is unchanged
    if ( oldTrackHull == assignHull )
        return;
    end
    
    [bLocked bCanChange] = Tracks.CheckLockedChangeLabel(oldAssignTrack, track, assignTime);
    if ( ~bCanChange )
        return;
    end
    
    if ( any(bLocked) && dir < 0 )
        return;
    end
    
    changedHulls = assignHull;
    if ( oldTrackHull > 0 )
        changedHulls = [changedHulls oldTrackHull];
    end
    
    if ( dir < 0 )
        % Makes sure track's start time is later than assignTime
        Families.RemoveFromTreePrune(track, trackTime);
        
        % In case trackIDs changed because of the tree removal
        track = Hulls.GetTrackID(trackHull);
        oldAssignTrack = Hulls.GetTrackID(assignHull);
    end
    
    if ( any(bLocked) )
        Tracks.LockedChangeLabel(oldAssignTrack, track, assignTime);
    else
        Tracks.ChangeLabel(oldAssignTrack, track, assignTime);
    end
end

