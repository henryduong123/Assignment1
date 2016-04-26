% AddNewSegmentHull.m - Attempt to add a completely new segmentation near
% the clicked point.

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

function newTrackID = AddNewSegmentHull(xyClickPt, time)
    global CellHulls
    
    chanImSet = Helper.LoadIntensityImageSet(time);
    chkHull = Segmentation.FindNewSegmentation(chanImSet, xyClickPt, 200, true, [], time);

    newHull = Helper.MakeEmptyStruct(CellHulls);
    newHull.userEdited = true;
    
    if ( ~isempty(chkHull) )
        chkHull = Segmentation.ForceDisjointSeg(chkHull, time, xyClickPt);
    end
    
    % TODO: Update manual click hulls for 3D
    rcImageDims = Metadata.GetDimensions('rc');
    if ( isempty(chkHull) )
        % Add a point hull since we couldn't find a segmentation containing the click
        clickIndex = Utils.CoordToInd(rcImageDims, round(Utils.SwapXY_RC(xyClickPt)));
        newHull = Hulls.CreateHull(rcImageDims, clickIndex, time, true, 'Manual');
    else
        newHull = Hulls.CreateHull(rcImageDims, chkHull.indexPixels, time, true, chkHull.tag);
    end
    
    newHullID = Hulls.SetCellHullEntries(0, newHull);
    Editor.LogEdit('Add', [], newHullID, true);
    
    newTrackID = Tracker.TrackAddedHulls(newHullID, newHull.centerOfMass);
end
