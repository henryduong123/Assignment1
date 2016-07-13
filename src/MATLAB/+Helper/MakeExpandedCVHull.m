
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

function expandPoints = MakeExpandedCVHull(hullPoints, expandRadius)
    expandPoints = [];
    if ( size(hullPoints,1) <= 1 )
        return;
    end
    
    planes = hullPoints(2:end,:) - hullPoints(1:(end-1),:);
    normPlanes = [-planes(:,2) planes(:,1)] ./ repmat(sqrt(sum(planes.^2, 2)), 1, 2);
    
    crossPlanes = (planes(:,1).*[planes(2:end,2);planes(1,2)] - [planes(2:end,1);planes(1,1)].*planes(:,2));
    if ( max(crossPlanes,[],1) > 0 )
        normPlanes = -normPlanes;
    end
    
    normPoints = (normPlanes + [normPlanes(end,:); normPlanes(1:(end-1),:)]) / 2;
    normDots = sum(normPlanes .* [normPlanes(end,:); normPlanes(1:(end-1),:)], 2);
    
    alphas = expandRadius ./ sqrt((1+normDots)/2);
    expandPoints = hullPoints + [[alphas alphas].*normPoints; alphas(1)*normPoints(1,:)];
end
