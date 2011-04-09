function UpdateHashedCellsTrackID(newTrackID,hulls,startTime)
%This will take the list of hulls and update their trackIDs to the given
%trackID

global HashedCells

for i=1:length(hulls)
    if(~hulls(i)),continue,end
    index = [HashedCells{startTime+i-1}(:).hullID]==hulls(i);
    %if(~isempty(index))
        HashedCells{startTime+i-1}(index).trackID = newTrackID;
    %end
end
end
