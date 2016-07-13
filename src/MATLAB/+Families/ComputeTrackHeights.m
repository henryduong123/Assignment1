
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

function trackHeights = ComputeTrackHeights(rootTrackID)
    
    trackHeights = containers.Map('KeyType', 'uint32', 'ValueType', 'uint32');
    roots = Families.GetFamilyRoots(rootTrackID);

    for i=1:length(roots)
        recursiveTrackHeights(roots(i), trackHeights); 
    end
end

function height = recursiveTrackHeights(trackID, trackHeights)
    global CellTracks
    
    if(~isempty(CellTracks(trackID).childrenTracks))
        leftHeight = recursiveTrackHeights(CellTracks(trackID).childrenTracks(1), trackHeights);
        rightHeight = recursiveTrackHeights(CellTracks(trackID).childrenTracks(2), trackHeights);
        
        height = 1 + max(leftHeight, rightHeight);
    else
        % leaf node
        height = 1;
    end
    
    trackHeights(trackID) = height;
end
