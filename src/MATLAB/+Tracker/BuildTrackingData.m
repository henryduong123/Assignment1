
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

function BuildTrackingData(hullTracks, gConnect)
    global Costs GraphEdits ResegLinks CellHulls CellFamilies CellTracks HashedCells CellPhenotypes

    %ensure that the globals are empty
    Costs = gConnect;
    GraphEdits = sparse([], [], [], size(Costs,1), size(Costs,2), round(0.1*size(Costs,2)));
    ResegLinks = sparse([], [], [], size(Costs,1), size(Costs,2), round(0.1*size(Costs,2)));
    
    CellFamilies = [];
    CellTracks = [];
    HashedCells = [];
    
    CellPhenotypes = struct('descriptions', {{'died'}}, 'hullPhenoSet', {zeros(2,0)});
    
    hullList = [];
    for i=length(hullTracks):-1:1
        UI.Progressbar((length(hullTracks)-i) / (length(hullTracks)));
        
        if ( any(ismember(hullList,i)) )
            continue;
        end
        
        allTrackHulls = find(hullTracks == hullTracks(i));
        hullList = [hullList addToTrack(allTrackHulls)];
    end
    
    if ( length(hullList) ~= length(CellHulls) )
        reprocess = setdiff(1:length(CellHulls), hullList);
        for i=1:length(reprocess)
            UI.Progressbar(i/length(reprocess));
            Families.NewCellFamily(reprocess(i));
        end
    end
    UI.Progressbar(1);
    
    Load.InitializeCachedCosts(1);
    
    errors = mexIntegrityCheck();
    if ( ~isempty(errors) )
        Dev.PrintIntegrityErrors(errors);
    end

    %create the family trees
    Families.ProcessNewborns();
end

function hullList = addToTrack(allTrackHulls)  
    if ( isempty(allTrackHulls) )
        return
    end

    Families.NewCellFamily(allTrackHulls(1));
    for i=2:length(allTrackHulls)
        Tracks.AddHullToTrack(allTrackHulls(i),[],allTrackHulls(i-1));
    end
    
    hullList = allTrackHulls;
end
