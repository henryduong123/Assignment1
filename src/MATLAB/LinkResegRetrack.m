function LinkResegRetrack()
    global HashedCells CellTracks CellFamilies
    
    LinkFirstFrameTrees();
    
    % Resegment and track
    goodTrees = [];
    for i=1:length(HashedCells{1})
        trackID = HashedCells{1}(i).trackID;
        familyID = CellTracks(trackID).familyID;
        endTime = CellFamilies(familyID).endTime;
        if ( endTime < length(HashedCells) )
            continue;
        end
    
        goodTracks = [goodTrees trackID];
    end
    
    ResegmentFromTree(goodTracks);
    
    ExternalRetrack();
    
    % Rerun tree-inference for first-frame cells
    LinkFirstFrameTrees();
end