% historyAction = LearnFromEdits()
% Edit Action:
% 
% Propagate segmentation edits forward.

function historyAction = LearnFromEdits(randState)
    global SegmentationEdits
    
    historyAction = '';
    
    if ( isempty(SegmentationEdits) || ((isempty(SegmentationEdits.newHulls) || isempty(SegmentationEdits.changedHulls))))
        return;
    end
    
    globStream = RandStream.getGlobalStream();
    globStream.State = randState;
    
    Tracks.PropagateChanges(SegmentationEdits.changedHulls, SegmentationEdits.newHulls);
    Families.ProcessNewborns();
    
    
    SegmentationEdits.newHulls = [];
    SegmentationEdits.changedHulls = [];
    UI.UpdateSegmentationEditsMenu();
    
    Helper.SweepDeleted();
    
    historyAction = 'Push';
end
