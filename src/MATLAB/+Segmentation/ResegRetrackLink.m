function ResegRetrackLink()
    global HashedCells CellTracks CellFamilies
    
%     [iters totalTime] = LinkFirstFrameTrees();
%     LogAction('Completed Tree Inference', [iters totalTime],[]);
    
    tic();
    % Resegment and track
    goodTracks = [];
    for i=1:length(HashedCells{1})
        trackID = HashedCells{1}(i).trackID;
        familyID = CellTracks(trackID).familyID;
        endTime = CellFamilies(familyID).endTime;
        if ( endTime < length(HashedCells) )
            continue;
        end
    
        goodTracks = [goodTracks trackID];
    end
    
    if ( isempty(goodTracks) )
        return;
    end
    
    Segmentation.ResegmentFromTree(goodTracks);
    tReseg = toc();
    
    tic();
    Tracker.HematoTracker();
    tRetrack = toc();
    Error.LogAction('Resegmentation/Tracking',[tReseg tRetrack],[]);
    
    % Rerun tree-inference for first-frame cells
    [iters totalTime] = Families.LinkFirstFrameTrees();
    Error.LogAction('Completed Tree Inference', [iters totalTime],[]);
end