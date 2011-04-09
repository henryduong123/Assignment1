function ContextRemoveFromTree(time,trackID)
%context menu callback function

%--Eric Wait

global CellTracks

oldFamilyID = CellTracks(trackID).familyID;

try
    newFamilyID = RemoveFromTree(time, trackID,'yes');
catch errorMessage
    try
        ErrorHandeling(['RemoveFromTree(' num2str(time) ' ' num2str(trackID) ' yes) -- ' errorMessage.message]);
        return
    catch errorMessage2
        fprintf(errorMessage2.message);
        return
    end
end
LogAction(['Removed part or all of ' num2str(trackID) ' from tree'],oldFamilyID,newFamilyID);

DrawTree(oldFamilyID);
DrawCells();
end
