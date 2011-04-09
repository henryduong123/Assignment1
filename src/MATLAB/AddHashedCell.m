function AddHashedCell(t,cellHullID,cellTrackID)
%This will either add an entry to HashedHulls or update an entry based on
%cellHullID

%--Eric Wait

global HashedCells

if(isempty(HashedCells))
    HashedCells = {struct('hullID',{cellHullID},'trackID',{cellTrackID})};
else
    if(t > length(HashedCells))
        HashedCells{t}(1).hullID = cellHullID;
        HashedCells{t}(1).trackID = cellTrackID;
    else
        %if the hullID exists update it, otherwise create the entry
        index = find([HashedCells{t}(:).hullID] == cellHullID);
        if(isempty(index))
            index = length(HashedCells{t}) + 1;
        end
        HashedCells{t}(index).hullID = cellHullID;
        HashedCells{t}(index).trackID = cellTrackID;
    end
end
end
