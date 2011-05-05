%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     This file is part of LEVer.exe
%     (C) 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function RemoveSegmentationEdit(rmHull)
    global SegmentationEdits
    
    if ( ~isempty(SegmentationEdits) )    
        % Remove the deleted hull from the edited segmentations lists
        SegmentationEdits.newHulls(SegmentationEdits.newHulls == rmHull) = [];
        SegmentationEdits.changedHulls(SegmentationEdits.changedHulls == rmHull) = [];
    end
    
    UpdateSegmentationEditsMenu();
end