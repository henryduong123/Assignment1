% historyAction = ChangeParent(Family ID, trackA, trackB, time)
% Edit Action:
% Switches Parents
% Toggles lock on familyID
% Context Swap Labels 
% Toggle lock on family ID
% Maria Enokian

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

function historyAction = ChangeParent(familyID,trackID,newTrackID, time)
% Initialized variables
global CellFamilies  CellTracks  Figures
trackID = CellTracks(trackID).parentTrack;
 trackA = trackID;
 trackB = newTrackID;
 Ntime = CellTracks(trackID).endTime; 
    Tracker.GraphEditSetEdge(trackA, trackB, Ntime);
    Tracker.GraphEditSetEdge(trackB, trackA, Ntime);
  
 % This will unlock the tree and if the cell family is locked it will
 % unlock it but otherwise it will lock it.
    if ( isempty(CellFamilies(familyID).bLocked) )
        CellFamilies(familyID).bLocked = false;
    end
    
    bIsLocked = CellFamilies(familyID).bLocked;
    Helper.SetTreeLocked(familyID, ~bIsLocked);
    % This will swap the two Parents together to correct the mitosis 
    bLocked = Helper.CheckTreeLocked([trackA trackB]);
    if ( any(bLocked) )
        Tracks.LockedSwapLabels(trackA, trackB, Ntime);
    else
        Tracks.SwapLabels(trackA, trackB, Ntime);
    end
 % This will unlock the tree and if the cell family is locked it will
 % unlock it but otherwise it will lock it.   
    if ( isempty(CellFamilies(familyID).bLocked) )
    CellFamilies(familyID).bLocked = 0;
    end
   
    bIsLocked = CellFamilies(familyID).bLocked;
    Helper.SetTreeLocked(familyID, ~bIsLocked);
    UI.DrawTree(Figures.tree.familyID);
    historyAction = 'Push';
end
