%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     This file is part of LEVer.exe
%     (C) 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
