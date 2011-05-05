%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     This file is part of LEVer.exe
%     (C) 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function RemoveTrackFromFamily(trackID)
% RemoveTrackFromFamily(trackID) only removes the track from the tracks
% list currently assosiated in the CellFamily entery and updated the other
% CellFamily fields.
% This is not intended to change the structure, just to keep the data
% correct


global CellFamilies CellTracks
familyID = CellTracks(trackID).familyID;
if(isempty(familyID)),return,end

index = CellFamilies(familyID).tracks==trackID;

%remove track
CellFamilies(familyID).tracks(index) = [];

%update times
[minimum index] = min([CellTracks(CellFamilies(familyID).tracks).startTime]);
CellFamilies(familyID).startTime = minimum;
CellFamilies(familyID).endTime = max([CellTracks(CellFamilies(familyID).tracks).endTime]);

%set new root
if(CellFamilies(familyID).rootTrackID == trackID)
    CellFamilies(familyID).rootTrackID = CellFamilies(familyID).tracks(index);
end
if(isempty(index))
    CellFamilies(familyID).tracks = [];
end
end
