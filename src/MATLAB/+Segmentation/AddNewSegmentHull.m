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

function newTrackID = AddNewSegmentHull(clickPt, time)
    global CONSTANTS CellHulls

    filename = Helper.GetFullImagePath(time);
    img = Helper.LoadIntensityImage(filename);
 
    if strcmp(CONSTANTS.cellType, 'Hemato')
        subSize = 100;
    else
        subSize = 200;
    end
    
    [newObj newFeat] = Segmentation.FindNewSegmentation(img, clickPt, subSize, 1.0, [], time);
    
    % Aggressive add segmentation
    if ( isempty(newObj) )
        for tryAlpha = 1.25:(-0.05):0.5
            [newObj newFeat] = Segmentation.FindNewSegmentation(img, clickPt, 200, tryAlpha, [], time);
            if ( ~isempty(newObj) )
                break;
            end
        end
    end

    newHull = Helper.MakeEmptyStruct(CellHulls);
    newHull.userEdited = true;
    
    if ( ~isempty(newObj) )
        newObj = Segmentation.ForceDisjointSeg(newObj, time, clickPt);
    end
    
    if ( isempty(newObj) )
        % Add a point hull since we couldn't find a segmentation containing the click
        newHull.time = time;
        newHull.points = round(clickPt);
        newHull.centerOfMass =  [clickPt(2) clickPt(1)];
        newHull.indexPixels = sub2ind(size(img), newHull.points(2), newHull.points(1));
        newHull.imagePixels = img(newHull.indexPixels);
    else
        newHull.time = time;
        newHull.points = newObj.points;
        [r c] = ind2sub(CONSTANTS.imageSize, newObj.indPixels);
        newHull.centerOfMass = mean([r c]);
        newHull.indexPixels = newObj.indPixels;
        newHull.imagePixels = newObj.imPixels;
    end
    
    newHullID = Hulls.SetHullEntries(0, newHull);
    
    newTrackID = Tracker.TrackAddedHulls(newHullID, newHull.centerOfMass);
end
