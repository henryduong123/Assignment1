% ReconnectParentWithChildren(parentTrack,children)
% Will connect the two children up with the parent
% Thows Error if:
%   length(children)~=2
%   children(1).startTime ~= children(2).startTime
%   parentTrack.endTime+1 ~= children(1).startTime
%   children have parents
%   parent has children

% ChangeLog
% EW 6/7/12 created
function ReconnectParentWithChildren(parentTrack,children)
global CellTracks Costs

%% Error Checking
if (length(children)~=2)
    list = sprintf(' %d, ',children);
    error('Not the right number of children, childrenIDs: %s',list);
end
if (CellTracks(children(1)).startTime ~= CellTracks(children(2)).startTime)
    error('Children times are not equivelent, lower: %d, higher: %d',children(1),children(2));
end
if (CellTracks(parentTrack).endTime+1 ~= CellTracks(children(1)).startTime)
    error('ParentTrack %d ends at %d and children start at %d',parentTrack,...
        CellTracks(parentTrack).endTime,CellTracks(children(1)).startTime);
end
if (~isempty(CellTracks(children(1)).parentTrack))
    error('Child %d already has parent', children(1));
end
if (~isempty(CellTracks(children(2)).parentTrack))
    error('Child %d already has parent', children(2));
end
if (~isempty(CellTracks(parentTrack).childrenTracks))
    error('Parent %d already has children %d & %d', parentTrack,...
        CellTracks(parentTrack).childrenTracks(1), CellTracks(parentTrack).childrenTracks(2));
end

%% Figure out which child should be on the left (lower cost child)
costs = [Costs(parentTrack,children(1)) Costs(parentTrack,children(2))];
[c index] = sort(costs);
children = children(index);

%% Connect up the track structure
CellTracks(children(1)).siblingTrack = children(2);
CellTracks(children(2)).siblingTrack = children(1);
CellTracks(children(1)).parentTrack = parentTrack;
CellTracks(children(2)).parentTrack = parentTrack;
CellTracks(parentTrack).childrenTracks = [children(1) children(2)];

%% Fix up the family structure
Families.ChangeTrackAndChildrensFamily(CellTracks(parentTrack).familyID,parentTrack);
end

