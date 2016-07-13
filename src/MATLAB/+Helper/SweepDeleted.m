% This is a LEVer garbage collection routine to clean up deleted
% tracks and families while keeping all data consistent.

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

function SweepDeleted()
    global CellHulls HashedCells CellTracks CellFamilies Costs ConnectedDist SegmentationEdits
    
%     remapCells = zeros(1,length(CellHulls));
    remapTracks = zeros(1,length(CellTracks));
    remapFamilies = zeros(1,length(CellFamilies));
    
    % Find all deleted cellss
%     bDeletedCells = [CellHulls.deleted];
%     remapCells(~bDeletedCells) = 1:nnz(~bDeletedCells);
    
%     hullRefList = cellfun(@(x)([x.hullID]), HashedCells, 'UniformOutput',false);
%     bCheckDeletedCells = ~ismember(1:length(CellHulls),unique([hullRefList{:}]));
%     if ( ~all(bCheckDeletedCells == bDeletedCells) )
%         error('Deleted Cells inconsistent');
%     end
    
    trackRefList = cellfun(@(x)([x.trackID]), HashedCells, 'UniformOutput',false);
    bEmptyTracks = arrayfun(@(x)(isempty(x.startTime)), CellTracks);
    bDeletedTracks = ~ismember(1:length(CellTracks),unique([trackRefList{:}]));
    remapTracks(~bDeletedTracks) = 1:nnz(~bDeletedTracks);
    
    if ( any(bEmptyTracks > bDeletedTracks) )
        error(['Referenced deleted tracks: ' num2str(find(bEmptyTracks > bDeletedTracks))]);
    elseif ( any(bEmptyTracks < bDeletedTracks) )
        error(['Unreferenced non-empty tracks: ' num2str(find(bEmptyTracks < bDeletedTracks))]);
    end
    
    familyRefs = unique([CellTracks.familyID]);
    bUnrefFamilies = ~ismember(1:length(CellFamilies),familyRefs);
    bEmptyFamilies = arrayfun(@(x)(isempty(x.startTime)), CellFamilies);
    remapFamilies(~bUnrefFamilies) = 1:nnz(~bUnrefFamilies);
    
    if ( any(bEmptyFamilies > bUnrefFamilies) )
        error(['Referenced deleted families: ' num2str(find(bEmptyFamilies > bUnrefFamilies))]);
    elseif ( any(bEmptyFamilies < bUnrefFamilies) )
        error(['Unreferenced non-empty families: ' num2str(find(bEmptyFamilies < bUnrefFamilies))]);
    end
    
%     newCellHulls = CellHulls(~bDeletedCells);
%     newCosts = Costs(~bDeletedCells,~bDeletedCells);
%     newConnDist = ConnectedDist(~bDeletedCells);

    newHash = HashedCells;
    newCellTracks = CellTracks(~bDeletedTracks);
    newCellFamilies = CellFamilies(~bUnrefFamilies);

    for t=1:length(newHash)
        for i=1:length(newHash{t})
            if ( remapTracks(newHash{t}(i).trackID) == 0 )
                error(['Hash cells reference deleted track: ' num2str(remapTracks(newHash{t}(i).trackID))]);
            end
            
            newHash{t}(i).trackID = remapTracks(newHash{t}(i).trackID);
        end
    end
    
    for i=1:length(newCellTracks)
        if ( remapFamilies(newCellTracks(i).familyID) == 0 )
            error(['Track references deleted family: ' num2str(newCellTracks(i).familyID)]);
        end
        
        if ( remapTracks(newCellTracks(i).parentTrack) == 0 )
            error(['Track references deleted parent: ' num2str(newCellTracks(i).parentTrack)]);
        end
        
        if ( remapTracks(newCellTracks(i).siblingTrack) == 0 )
            error(['Track references deleted sibling: ' num2str(newCellTracks(i).siblingTrack)]);
        end
        
        if ( any(remapTracks(newCellTracks(i).childrenTracks) == 0) )
            error(['Track references deleted children: ' num2str(newCellTracks(i).childrenTracks(remapTracks(newCellTracks(i).childrenTracks) == 0))]);
        end
        
        newCellTracks(i).familyID = remapFamilies(newCellTracks(i).familyID);
        
        newCellTracks(i).parentTrack = remapTracks(newCellTracks(i).parentTrack);
        newCellTracks(i).siblingTrack = remapTracks(newCellTracks(i).siblingTrack);
        newCellTracks(i).childrenTracks = remapTracks(newCellTracks(i).childrenTracks);
    end
    
    for i=1:length(newCellFamilies)
        if ( remapTracks(newCellFamilies(i).rootTrackID) == 0 )
            error(['Family references deleted root track: ' num2str(newCellFamilies(i).rootTrackID)]);
        end
        
        if ( any(remapTracks(newCellFamilies(i).tracks) == 0) )
            error(['Family references deleted tracks: ' num2str(newCellFamilies(i).tracks(remapTracks(newCellFamilies(i).tracks) == 0))]);
        end
        
        newCellFamilies(i).rootTrackID = remapTracks(newCellFamilies(i).rootTrackID);
        newCellFamilies(i).tracks = remapTracks(newCellFamilies(i).tracks);
    end
    
    HashedCells = newHash;
    CellTracks = newCellTracks;
    CellFamilies = newCellFamilies;
end

