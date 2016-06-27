
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

function roots = GetFamilyRoots(rootTrackID)
    global CellFamilies CellTracks
    
    familyID = CellTracks(rootTrackID).familyID;
    family = CellFamilies(familyID);
    if (isfield(CellFamilies, 'extFamily') && ~isempty(family.extFamily))
        roots = [CellFamilies(family.extFamily).rootTrackID];
    else
        roots = CellFamilies(familyID).rootTrackID;
    end
    
    rootFamilies = [CellTracks(roots).familyID];
    numTracks = arrayfun(@(x)(length(x.tracks)),CellFamilies(rootFamilies));

    [~,srtIdx] = sort(numTracks,'descend');
    roots = roots(srtIdx);
end
