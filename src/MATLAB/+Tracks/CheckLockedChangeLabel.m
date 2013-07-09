% [bLocked bCanChange] = CheckLockedChangeLabel(currentTrack, desiredTrack, time)
%
% This function will check to verify if a tree-preserving change-label
% needs to be run for the requested change, and if it will succeed.

function [bLocked bCanChange] = CheckLockedChangeLabel(currentTrack, desiredTrack, time)
    global CellTracks
    
    bCanChange = 1;
    bLocked = Helper.CheckLocked([currentTrack desiredTrack]);
    
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
