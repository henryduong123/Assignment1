function bFinished = ResegFromTreeInteractive()
    global Figures CellTracks CellFamilies HashedCells CellHulls Costs ResegState
    
    bFinished = 0;
    
    preserveTracks = [CellFamilies(ResegState.preserveFamilies).tracks];

    % Need to worry about deleted hulls?
    costMatrix = Costs;
    bDeleted = ([CellHulls.deleted] > 0);
    costMatrix(bDeleted,:) = 0;
    costMatrix(:,bDeleted) = 0;

    mexDijkstra('initGraph', costMatrix);
    
    tStart = ResegState.currentTime;
    tMax = length(HashedCells);
    tEnd = tMax;
    
    for t=tStart:tEnd
        newPreserveTracks = Segmentation.ResegFromTree.FixupSingleFrame(t, preserveTracks, tMax);
        
        preserveTracks = [preserveTracks newPreserveTracks];
        [dump sortedIdx] = unique(preserveTracks, 'first');
        sortedIdx = sort(sortedIdx);
        preserveTracks = preserveTracks(sortedIdx);
        
        bInvalidPreserveTracks = cellfun(@(x)(isempty(x)),{CellTracks(preserveTracks).startTime});
        preserveTracks = preserveTracks(~bInvalidPreserveTracks);
        
        ResegState.currentTime = t+1;
        Editor.History('Push');
        
        Figures.time = t;
        UI.DrawTree(ResegState.primaryTree);
        UI.DrawCells();
        
        % Do not remove, guarantees UI callbacks from toolbar are
        % processed.
        drawnow();
        
        if ( isempty(ResegState) )
            return;
        end
        
        if ( ResegState.bPaused )
            return;
        end
    end
    
    bFinished = 1;
end
