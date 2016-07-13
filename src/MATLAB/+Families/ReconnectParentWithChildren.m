% ReconnectParentWithChildren(parentTrack,children)
% Will connect the two children up with the parent
% Thows Error if:
%   length(children)~=2
%   children(1).startTime ~= children(2).startTime
%   parentTrack.endTime+1 ~= children(1).startTime
%   children have parents
%   parent has children

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

%% Connect up the track structure
CellTracks(children(1)).siblingTrack = children(2);
CellTracks(children(2)).siblingTrack = children(1);
CellTracks(children(1)).parentTrack = parentTrack;
CellTracks(children(2)).parentTrack = parentTrack;
CellTracks(parentTrack).childrenTracks = [children(1) children(2)];

%% Fix up the family structure
Families.ChangeTrackAndChildrensFamily(CellTracks(parentTrack).familyID,parentTrack);
end

