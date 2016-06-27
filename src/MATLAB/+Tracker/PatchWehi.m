% PatchWehi()
% Loop through each time interval. If a new track gets created at time
% t, try to change it to its second choice at time t-1. Runs before any
% user edits have taken place.

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

function PatchWehi()
    fprintf('Running Wehi patcher...');
    tic;
    
    global CellTracks HashedCells Costs
        
    for t = 1:size(HashedCells,2) - 1
        fromCells = HashedCells{t};
        toCells = HashedCells{t+1};
        len = size(fromCells, 2);

        % If we have a different number of cells on the 2 frames, just punt
        % and let the user edit it by hand
        if len ~= size(toCells,2)
            continue;
        end
        
        % find the from and to hulls (if any) whose tracks split here
        fromHulls = [];
        fromIdx = [];
        for i = 1:len
            hullID = fromCells(i).hullID;
            trackID = fromCells(i).trackID;
            if CellTracks(trackID).endTime == t
                fromHulls = [fromHulls hullID];
                fromIdx = [fromIdx i];
            end
        end
        if isempty(fromHulls)
            continue;
        end

        toHulls = [];
        toIdx = [];
        for i = 1:len
            hullID = toCells(i).hullID;
            trackID = toCells(i).trackID;
            if CellTracks(trackID).startTime == t+1
                toHulls = [toHulls hullID];
                toIdx = [toIdx i];
            end
        end
        if isempty(toHulls)
            continue;
        end

        % extract (nonsparse) costs for these hulls
        cst = full(Costs(fromHulls, toHulls));
        
        % make things simpler by changing all the 0s to Inf
        for i = 1:size(cst, 1)
            for j = 1:size(cst, 2)
                if cst(i,j) == 0
                    cst(i,j) = Inf;
                end
            end
        end
        
        % now repeatedly join the from and to cells with the lowest cost
        [r c] = findLowCost(cst);
        while (r ~= 0)
            % change the label
            from = fromIdx(r);
            to = toIdx(c);
            Tracks.ChangeLabel(toCells(to).trackID, fromCells(from).trackID, t+1);
            
            % reset row r and column c to Inf
            for i = 1:size(cst,1)
                cst(i,c) = Inf;
            end
            for i = 1:size(cst,2)
                cst(r,i) = Inf;
            end
            
            % try to find another low cost cell
            [r c] = findLowCost(cst);
        end
        
%     
%         
%         for i = 1:len
%             hullID = Cells(i).hullID;
%             trackID = Cells(i).trackID;
%             
%             % does the track end here?
%             if CellTracks(trackID).endTime == t
%                 % see if we can assign it to the second-best track
%                 sbTrackID = secondBestTrack(hullID, newCells);
%                 if sbTrackID ~= 0 && CellTracks(sbTrackID).startTime == t+1
%                     Tracks.ChangeLabel(sbTrackID,trackID,t+1);
%                 end
%             end
%         end
    end
    
    fprintf('Done.');
    toc;
end

function[r c] = findLowCost(cst)
    lowCost = Inf;
    lowRow = 0;
    lowCol = 0;
    
    for i=1:size(cst,1)
        for j = 1:size(cst,2)
            if cst(i,j) < lowCost
                lowCost = cst(i,j);
                lowRow = i;
                lowCol = j;
            end
        end
    end
    
    r = lowRow;
    c = lowCol;
end

function sbTrackID = secondBestTrack(hullID, newCells)
    global Costs
    
    % find the second-lowest cost for this hull
    c = sort(Costs(hullID, [newCells.hullID]));
    cnt = 0;
    cost = 0;
    for i = 1:size(c,2)
        if c(1,i) ~= 0
            cnt = cnt + 1;
            if cnt == 2
                cost = c(1,i);
                break;
            end
        end
    end
    
    % find the trackID with that cost
    sbTrackID = 0;
    if cost > 0
        hulls = [newCells.hullID];
        for i = 1:size(hulls,2)
            if Costs(hullID, hulls(i)) == cost
                sbTrackID = newCells(i).trackID;
                break;
            end
        end
    end
end
