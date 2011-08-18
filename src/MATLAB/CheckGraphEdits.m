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

% Depending on tracking direction add and remove to/from hulls so that all
% user graph edits are accounted for within the tracker.
function [trackHulls,nextHulls] = CheckGraphEdits(dir, fromHulls, toHulls)
    global GraphEdits CellHulls
    
    nextHulls = toHulls;
    trackHulls = fromHulls;
    
    if ( isempty(toHulls) )
        return;
    end
    
    if ( dir > 0 )
        inEdits = GraphEdits;
    else
        inEdits = GraphEdits';
    end
    
    if ( dir > 0 )
        needTrackHulls = find(any(inEdits(:,toHulls) == 1,2));
        needNextHulls = find(any(inEdits(fromHulls,:) == 1,1));
        
        editedFromHulls = fromHulls(any(inEdits(fromHulls,:) > 0,2));
        editedToHulls = toHulls(any(inEdits(:,toHulls) > 0,1));
        
        trackHulls = setdiff(trackHulls, editedFromHulls);
        nextHulls = setdiff(nextHulls, editedToHulls);
    else
        needNextHulls = [];
        needTrackHulls = find(any(inEdits(:,toHulls) > 0,2));
        editedFromHulls = fromHulls(any(inEdits(fromHulls,:) > 0,2));
        trackHulls = setdiff(trackHulls, editedFromHulls);
    end
    
    trackHulls = union(trackHulls,needTrackHulls);
    nextHulls = union(nextHulls,needNextHulls);
    
    bDeleted = find([CellHulls(trackHulls).deleted]);
    trackHulls(bDeleted)=[];
    
    bDeleted = find([CellHulls(nextHulls).deleted]);
    nextHulls(bDeleted)=[];
    
    
end

