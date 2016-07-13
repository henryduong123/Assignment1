% FindLargestTree.m - Finds the largest tree in this data set.

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

function FindLargestTree(src,evnt)
global CellFamilies Figures

if ( isfield(CellFamilies, 'bLocked') )
    lockedTrees = find([CellFamilies.bLocked] ~= 0);
    if ( ~isempty(lockedTrees) )
        maxLockedTree = lockedTrees(1);
        for i=2:length(lockedTrees)
            if ( length(CellFamilies(maxLockedTree).tracks) < length(CellFamilies(lockedTrees(i)).tracks) )
                maxLockedTree = lockedTrees(i);
            end
        end

        Figures.tree.familyID = maxLockedTree;
        UI.DrawTree(maxLockedTree);
        UI.DrawCells();

        return;
    end
end

maxID = 1;
for i=2:length(CellFamilies)
    if(length(CellFamilies(maxID).tracks) < length(CellFamilies(i).tracks))
        maxID = i;
    end
end 
if(isfield(Figures.tree,'FamilyID') && Figures.tree.familyID == maxID),return,end

Figures.tree.familyID = maxID;
UI.DrawTree(maxID);
UI.DrawCells();
end