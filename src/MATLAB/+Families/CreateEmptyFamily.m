% familyID = CreateEmptyFamily()
% Creates an empty family with each of the fields set to [] and returns the
% new family id.

function familyID = CreateEmptyFamily()
    global CellFamilies
    familyID = length(CellFamilies) +1;
    
    % Get all field names dynamically and clear them
    strFieldNames = fieldnames(CellFamilies);
    for i=1:length(strFieldNames)
        CellFamilies(familyID).(strFieldNames{i}) = [];
    end
    CellFamilies(familyID).bLocked = false;
end

