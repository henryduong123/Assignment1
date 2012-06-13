% UpdatePhenotypeInfo.m - Attempt to update old LEVer file type phenotype
% info to the new format.

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

function UpdatePhenotypeInfo()
    global CellPhenotypes CellTracks
    % non-empty tracks?
    if ~isfield(CellTracks,'phenotype')
        CellTracks(1).phenotype=[];
    end
    netracks = find(arrayfun(@(x)(~isempty(x.phenotype)), CellTracks));
    bPhenoCells = ([CellTracks(netracks).phenotype] > 0);

    phenoTracks = netracks(bPhenoCells);
    
    if ( isempty(CellPhenotypes) || ~isfield(CellPhenotypes,'descriptions') )
        CellPhenotypes = struct('descriptions', {{'died'}}, 'contextMenuID', {[]});
    end
    
    oldCellPheno = CellPhenotypes;
    CellPhenotypes = struct('descriptions', {oldCellPheno.descriptions}, 'contextMenuID', {oldCellPheno.contextMenuID}, 'hullPhenoSet', cell(size(oldCellPheno)));
    
    for i=1:length(phenoTracks)
        phenotype = CellTracks(phenoTracks(i)).phenotype;
        if ( phenotype == 1 )
            markedTime = CellTracks(phenoTracks(i)).timeOfDeath;
            hash = markedTime - CellTracks(phenoTracks(i)).startTime + 1;
            markedHull = CellTracks(phenoTracks(i)).hulls(hash);
        else
            markedHull = CellTracks(phenoTracks(i)).hulls(find(CellTracks(phenoTracks(i)).hulls > 0,1,'last'));
        end
        
        if ( isempty(markedHull) || (markedHull == 0) )
            continue;
        end
        
        Tracks.SetPhenotype(markedHull, phenotype, 0);
    end
    
    CellTracks = rmfield(CellTracks, 'phenotype');
    CellTracks = rmfield(CellTracks, 'timeOfDeath');
end

