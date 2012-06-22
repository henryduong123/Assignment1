% LearnFromEdits()
% Edit Action:
% Propagate segmentation edits forward.

function LearnFromEdits()
    global SegmentationEdits
    
    if ( isempty(SegmentationEdits) || ((isempty(SegmentationEdits.newHulls) || isempty(SegmentationEdits.changedHulls))))
        return;
    end
    
    Tracks.PropagateChanges(SegmentationEdits.changedHulls, SegmentationEdits.newHulls);
    Families.ProcessNewborns();
    
    
    SegmentationEdits.newHulls = [];
    SegmentationEdits.changedHulls = [];
    UI.UpdateSegmentationEditsMenu();
    
    Helper.SweepDeleted();
end