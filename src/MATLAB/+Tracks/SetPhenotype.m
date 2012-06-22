% SetPhenotype(hullID, phenotype, bActive)
% Set the phenotype at the specified hullID. In the process clears other
% phenotypes set for this hull's track.

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

function SetPhenotype(hullID, phenotype, bActive)
    global CellPhenotypes

    if ( isempty(CellPhenotypes.hullPhenoSet) )
        CellPhenotypes.hullPhenoSet = zeros(2,0);
    end
    
    unsetTrackPhenotype(hullID);
    
    if ( bActive || phenotype == 0 )
        return;
    end
    
    [newHulls newIdx] = unique([CellPhenotypes.hullPhenoSet(1,:) hullID]);
    newPheno = [CellPhenotypes.hullPhenoSet(2,:) phenotype];
    
    CellPhenotypes.hullPhenoSet = [newHulls; newPheno(newIdx)];
    
    Error.LogAction(['Activated phenotype ' CellPhenotypes.descriptions{phenotype} ' for track ' num2str(Hulls.GetTrackID(hullID))]);
end

function unsetTrackPhenotype(hullID)
    global CellPhenotypes

    trackID = Hulls.GetTrackID(hullID);
    [oldPhen resetHulls] = Tracks.GetAllTrackPhenotypes(trackID);
    
    unsetPhenotype(resetHulls);
    
    if ( isempty(CellPhenotypes.hullPhenoSet) )
        CellPhenotypes.hullPhenoSet = zeros(2,0);
    end
    
end

function unsetPhenotype(hullIDs)
    global CellPhenotypes
    
    rmPhen = getHullPhenos(hullIDs);
    
    [newHulls newIdx] = setdiff(CellPhenotypes.hullPhenoSet(1,:), hullIDs);
    newPheno = CellPhenotypes.hullPhenoSet(2,newIdx);
    
    CellPhenotypes.hullPhenoSet = [newHulls; newPheno];
    
    if ( ~isempty(rmPhen) && all(rmPhen > 0) )
        Error.LogAction(['Deactivated phenotype ' CellPhenotypes.descriptions{rmPhen(end)} ' for track ' num2str(Hulls.GetTrackID(hullIDs(end)))]);
    end
end

function phenos = getHullPhenos(hullIDs)
    global CellPhenotypes
    
    phenos = zeros(size(hullIDs));
    
    if ( isempty(CellPhenotypes.hullPhenoSet) )
        return;
    end
    
    [bMember idx] = ismember(hullIDs, CellPhenotypes.hullPhenoSet(1,:));
    phenos(bMember) = CellPhenotypes.hullPhenoSet(2,idx(bMember));
end

