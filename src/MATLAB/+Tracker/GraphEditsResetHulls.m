% GraphEditsResetHulls(hulls, bResetForward, bResetBack)
% 
% Clears all user edits into (bResetBack) and/or out of (bResetForward)
% a hull, updates associated cached costs.

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


function GraphEditsResetHulls(hulls, bResetForward, bResetBack)
    global Costs GraphEdits
    
    if ( ~exist('bResetForward','var') )
        bResetForward = 1;
    end
    
    if ( ~exist('bResetBack','var') )
        bResetBack = 1;
    end
    
    toHulls = hulls;
    fromHulls = hulls;
    
    if ( ~bResetForward && ~bResetBack )
        return;
    end
    
    for i=1:length(hulls)
        toHulls = union(toHulls, find((Costs(hulls(i),:) > 0) | (GraphEdits(hulls(i),:) > 0)));
        fromHulls = union(fromHulls, find((Costs(:,hulls(i)) > 0) | (GraphEdits(:,hulls(i)) > 0)));
    end
    
    if ( bResetForward )
        for i=1:length(hulls)
            GraphEdits(hulls(i),:) = 0;
        end
    end
    
    if ( bResetBack )
        for i=1:length(hulls)
            GraphEdits(:,hulls(i)) = 0;
        end
    end
    
    Tracker.UpdateCachedCosts(fromHulls, toHulls);
end
