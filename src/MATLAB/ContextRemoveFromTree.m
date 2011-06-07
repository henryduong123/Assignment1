%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     This file is part of LEVer.exe
%     (C) 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ContextRemoveFromTree(time,trackID)
%context menu callback function


global CellTracks

oldFamilyID = CellTracks(trackID).familyID;

try
    newFamilyID = RemoveFromTree(time, trackID,'yes');
    History('Push');
catch errorMessage
    try
        ErrorHandeling(['RemoveFromTree(' num2str(time) ' ' num2str(trackID) ' yes) -- ' errorMessage.message],errorMessage.stack);
        return
    catch errorMessage2
        fprintf('%s',errorMessage2.message);
        return
    end
end
LogAction(['Removed part or all of ' num2str(trackID) ' from tree'],oldFamilyID,newFamilyID);

DrawTree(oldFamilyID);
DrawCells();
end
