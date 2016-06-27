
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     Copyright 2011-2016 Andrew Cohen
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

function ccDist = CalcHullConnectedDistances(hullID, nextHullIDs, hullPerims, hulls)
    global CONSTANTS
    
    ccDist = Inf*ones(1,length(nextHullIDs));
    
    if ( isempty(nextHullIDs) )
        return;
    end
    
    t = hulls(hullID).time;
    tNext = vertcat(hulls(nextHullIDs).time);
    
    tDist = abs(tNext-t);
    comDistSq = sum((ones(length(nextHullIDs),1)*hulls(hullID).centerOfMass - vertcat(hulls(nextHullIDs).centerOfMass)).^2, 2);
    
    chkHullIdx = find(comDistSq <= (tDist*CONSTANTS.dMaxCenterOfMass).^2);
    checkHullIDs = nextHullIDs(chkHullIdx);
    
    if ( isempty(checkHullIDs) )
        return;
    end
    
    rcImageDims = Metadata.GetDimensions('rc');
    for i=1:length(checkHullIDs)
        chkDist = Helper.CalcConnectedDistance(hullID,checkHullIDs(i), rcImageDims, hullPerims, hulls);
        ccDist(chkHullIdx(i)) = chkDist;
    end
end
