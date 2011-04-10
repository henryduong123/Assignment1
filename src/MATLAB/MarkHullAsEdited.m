function MarkHullAsEdited(hullIDs,time,unmark)
% MarkHullAsEdited(hullID,time) will flag the given hull(s) in HashedCells as
% edited.  Pass time in if known (function runs faster) and if all the
% hulls are on the same frame.  Pass unmark=1 if you want the hull to be
% unflaged.

global HashedCells CellHulls

if(~exist('unmark','var'))
    unmark = 0;
end

if(exist('time','var'))
    HashedCells{time}(ismember([HashedCells{time}.hullID],hullIDs)).editedFlag = ~unmark;
else
    for i = 1:length(hullIDs)
    end
end
end