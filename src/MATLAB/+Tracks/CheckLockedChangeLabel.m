% [bLocked bCanChange] = CheckLockedChangeLabel(currentTrack, desiredTrack, time)
%
% This function will check to verify if a tree-preserving change-label
% needs to be run for the requested change, and if it will succeed.

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


function [bLocked bCanChange] = CheckLockedChangeLabel(currentTrack, desiredTrack, time)
    global CellTracks
    
    bCanChange = 1;
    bLocked = Helper.CheckTreeLocked([currentTrack desiredTrack]);
    
    % Current track is on locked tree
    if ( bLocked(1) )
        if ( any(time == [CellTracks(currentTrack).startTime CellTracks(currentTrack).startTime]) )
            bCanChange = 0;
            return;
        end
        
        curChildren = CellTracks(currentTrack).childrenTracks;
        if ( ~isempty(curChildren) && (time == CellTracks(currentTrack).endTime) )
            bCanChange = 0;
            return;
        end
    end
    
    % Desired track is on locked tree
    % Note: will only "break" structure if the new hull is past the end of
    % a track (that has children).
    if ( bLocked(2) )
        if ( time > CellTracks(desiredTrack).endTime && ~isempty(CellTracks(desiredTrack).childrenTracks) )
            bCanChange = 0;
            return;
        end
    end
    
    
end
