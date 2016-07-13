
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


% UpdateLog:
% EW 6/6/12 Created
function UpdateFamilyTimes( familyID )
global CellFamilies CellTracks

tracks = CellFamilies(familyID).tracks;

if (isempty(tracks))
    CellFamilies(familyID).endTime = [];
    CellFamilies(familyID).startTime = [];
    CellFamilies(familyID).correctedTime = [];
    
    CellFamilies(familyID).rootTrackID = [];
    CellFamilies(familyID).bLocked = false;
	CellFamilies(familyID).bCompleted = false;
    CellFamilies(familyID).bFrozen = false;
    CellFamilies(familyID).extFamily = [];
    return;
end

times = [CellTracks(tracks).endTime];
CellFamilies(familyID).endTime = max(times);

times = [CellTracks(tracks).startTime];
[CellFamilies(familyID).startTime index] = min(times);

if ( CellFamilies(familyID).correctedTime > CellFamilies(familyID).endTime )
    CellFamilies(familyID).correctedTime = CellFamilies(familyID).endTime;
end

CellFamilies(familyID).rootTrackID = tracks(index);
end
