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

function PropagateBackward(time)
    global HashedCells CellTracks CellPhenotypes

    phenoTracks = [];
    if ( ~isempty(CellPhenotypes.hullPhenoSet) )
        phenoTracks = unique(GetTrackID(CellPhenotypes.hullPhenoSet(1,:)));
    end

    hullList = [];
    for i=1:length(phenoTracks)
        if ( GetTrackPhenotype(phenoTracks(i)) == 1 )
            markedIdx = GetTimeOfDeath(phenoTracks(i)) - CellTracks(phenoTracks(i)).startTime + 1;
            markedHull = CellTracks(phenoTracks(i)).hulls(markedIdx);
            if ( markedHull == 0 )
                continue;
            end
        else
            markedIdx = find(CellTracks(phenoTracks(i)).hulls, 1, 'last');
            if ( isempty(markedIdx) )
                continue;
            end
            markedHull = CellTracks(phenoTracks(i)).hulls(markedIdx);
        end

        hullList = [hullList markedHull];
    end

    curCells = [HashedCells{time}.hullID];
    if ( isempty(curCells) )
        return;
    end

    TrackBackPhenotype(hullList, curCells);
end