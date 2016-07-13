
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

function newHull = CreateHull(rcImageDims, indexPixels, time, userEdited, tag)
    global CellHulls
    
    if ( ~exist('time','var') )
        time = 1;
    end
    
    if ( ~exist('userEdited','var') )
        userEdited = false;
    end
    
    if ( ~exist('tag','var') )
        tag = '';
    end
    
    newHull = [];
    if ( ~isempty(CellHulls) )
        newHull = Helper.MakeEmptyStruct(CellHulls);
    end
    
    rcCoords = Utils.IndToCoord(rcImageDims, indexPixels);
    xyCoords = Utils.SwapXY_RC(rcCoords);
    
    newHull.indexPixels = indexPixels;
    newHull.centerOfMass = mean(rcCoords,1);
        
    chIdx = Helper.ConvexHull(xyCoords(:,1), xyCoords(:,2));
    if ( isempty(chIdx) )
        newHull = [];
        return;
    end

    newHull.points = xyCoords(chIdx,1:2);
    
    newHull.time = time;
    newHull.userEdited = (userEdited > 0);
    newHull.tag = tag;
end
