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