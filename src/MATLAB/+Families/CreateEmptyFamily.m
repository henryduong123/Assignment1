% familyID = CreateEmptyFamily()
% Creates an empty family with each of the fields set to [] and returns the
% new family id.

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


function familyID = CreateEmptyFamily()
    global CellFamilies
    familyID = length(CellFamilies) +1;
    
    % Get all field names dynamically and clear them
    strFieldNames = fieldnames(CellFamilies);
    for i=1:length(strFieldNames)
        CellFamilies(familyID).(strFieldNames{i}) = [];
    end
    CellFamilies(familyID).bLocked = false;
    CellFamilies(familyID).bFrozen = false;
    CellFamilies(familyID).extFamily = [];
    CellFamilies(familyID).bCompleted = false;
    CellFamilies(familyID).correctedTime = 0;
end

