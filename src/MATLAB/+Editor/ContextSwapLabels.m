% historyAction = ContextSwapLabels(trackA, trackB, time)
% Edit Action:
% 
% Swap tracking for tracks A and B beginning at specified time.

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


function historyAction = ContextSwapLabels(trackA, trackB, time)
    
    Tracker.GraphEditSetEdge(trackA, trackB, time);
    Tracker.GraphEditSetEdge(trackB, trackA, time);
    
    bLocked = Helper.CheckTreeLocked([trackA trackB]);
    if ( any(bLocked) )
        Tracks.LockedSwapLabels(trackA, trackB, time);
    else
        Tracks.SwapLabels(trackA, trackB, time);
    end
    
    historyAction = 'Push';
end
