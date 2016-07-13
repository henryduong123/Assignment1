% historyAction = ContextSetPhenotype(trackID, phenotype, bActive)
% Edit Action:
% 
% Sets or clears the phenotype specified for the given hull. If the
% phenotype is "dead" there is also some special handling to drop children.

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


function historyAction = ContextSetPhenotype(hullID, phenotype, bActive)
    global CellPhenotypes
    
    trackID = Hulls.GetTrackID(hullID);

    % If the phenotype is being set to "dead" then straighten children
    % before setting the phenotype
    if ( ~bActive && phenotype == 1 )
        Tracks.StraightenTrack(trackID);
    end
%     If the phenotype is being set to "ambiguous" then straighten children
%     before setting the phenotype
%     if ( ~bActive && phenotype == 2 )
%         Tracks.StraightenTrack(trackID);
%     end
%         If the phenotype is being set to "off screen" then straighten children
%     before setting the phenotype
%     if ( ~bActive && phenotype == 3)
%         Tracks.StraightenTrack(trackID);
%     end
    Tracks.SetPhenotype(hullID, phenotype, bActive);
    
    historyAction = 'Push';
end
