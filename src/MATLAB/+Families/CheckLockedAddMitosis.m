% [bLocked bCanAdd] = CheckLockedAddMitosis(parentTrack, leftChildTrack, siblingTrack, time)
%
% This function will check to verify if a "tree-preserving" add mitosis is
% possible.

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


function [bLockedParent bLockedChildren bCanAdd] = CheckLockedAddMitosis(parentTrack, leftChildTrack, siblingTrack, time)
    global CellTracks
    
    bCanAdd = false;
    
    bLockedParent = Helper.CheckTreeLocked(parentTrack);
    
    checkChildren = [siblingTrack leftChildTrack];
    bLockedChildren = Helper.CheckTreeLocked(checkChildren);
    
    if ( bLockedParent )
        % Add mitosis would cause at least a subtree on locked tree to be removed
        if ( ~isempty(CellTracks(parentTrack).childrenTracks) )
            % Parent is locked and would change mitosis edges
            if ( CellTracks(parentTrack).endTime == time-1 )
                return;
            end
            
            % Parent locked and would replace children
            if ( (length(checkChildren) == 2) )
                return;
            end
        end
    end
    
    if ( any(bLockedChildren) )
        bNonrootTracks = arrayfun(@(x)(~isempty(x.parentTrack)), CellTracks(checkChildren));
        
        lockedStarts = [CellTracks(checkChildren(bLockedChildren & bNonrootTracks)).startTime];
        lockedEnds = [CellTracks(checkChildren(bLockedChildren)).endTime];
        
        if ( any(lockedStarts == time) || any(lockedEnds == time) )
            return;
        end
    end
    
    bCanAdd = true;
end