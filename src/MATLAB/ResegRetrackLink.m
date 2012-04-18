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
    
    ResegmentFromTree(goodTracks);
    tReseg = toc();
    
    tic();
    ExternalRetrack();
    tRetrack = toc();
    LogAction('Resegmentation/Tracking',[tReseg tRetrack],[]);
    
    % Rerun tree-inference for first-frame cells
    [iters totalTime] = LinkFirstFrameTrees();
    LogAction('Completed Tree Inference', [iters totalTime],[]);
end