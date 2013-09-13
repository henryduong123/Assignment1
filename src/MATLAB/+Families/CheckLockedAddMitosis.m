% [bLocked bCanAdd] = CheckLockedAddMitosis(parentTrack, leftChildTrack, siblingTrack, time)
%
% This function will check to verify if a "tree-preserving" add mitosis is
% possible.

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