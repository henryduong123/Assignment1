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

function AddHashedCell(t,cellHullID,cellTrackID)
%This will either add an entry to HashedHulls or update an entry based on
%cellHullID


global HashedCells

if(isempty(HashedCells))
    HashedCells{t}(1).hullID = cellHullID;
    HashedCells{t}(1).trackID = cellTrackID;
%     HashedCells = {struct('hullID',{cellHullID},'trackID',{cellTrackID})};
else
    if(t > length(HashedCells))
        HashedCells{t}(1).hullID = cellHullID;
        HashedCells{t}(1).trackID = cellTrackID;
    else
        %if the hullID exists update it, otherwise create the entry
        if(t>length(HashedCells) || isempty(HashedCells{t}))
            index = 1;
        else
            index = find([HashedCells{t}(:).hullID] == cellHullID);
            if(isempty(index))
                index = length(HashedCells{t}) + 1;
            end
        end
        HashedCells{t}(index).hullID = cellHullID;
        HashedCells{t}(index).trackID = cellTrackID;
    end
end
end
