%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     This file is part of LEVer.exe
%     (C) 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function hullID = FindHull(curPoint)
%This function will find the closest hull to the given point and return the
%hullID if it is within CONSTANTS.clickMargin


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
