% FindHull.m - This function will find the closest hull to the given point
% and return the hullID if it is within CONSTANTS.clickMargin

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

function hullID = FindHull(curPoint)

global CONSTANTS CellHulls HashedCells Figures

centerOfMasses = reshape([CellHulls([HashedCells{Figures.time}(:).hullID]).centerOfMass]',2,[])';
distance = (curPoint(1)-centerOfMasses(:,2)).^2 + (curPoint(3)-centerOfMasses(:,1)).^2;
[distance index] = min(distance);

if (distance <= CONSTANTS.clickMargin)
    hulls = [HashedCells{Figures.time}(:).hullID];
    hullID = hulls(index);
else
    hullID = -1;
end
end
