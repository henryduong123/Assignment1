function bFinished = ResegFromTreeInteractive()
    global Figures CellTracks CellFamilies HashedCells CellHulls Costs ResegState bResegPaused
    
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
        Editor.History('Push',t);
        
        Figures.time = t;
        UI.DrawTree(ResegState.primaryTree);
        UI.DrawCells();
        
        xlims = get(Figures.tree.axesHandle,'XLim');
        hold(Figures.tree.axesHandle,'on');
        plot(Figures.tree.axesHandle, [xlims(1), xlims(2)],[t, t], '-b');
        hold(Figures.tree.axesHandle,'off');
        
        % Do not remove, guarantees UI callbacks from toolbar are
        % processed.
        drawnow();
        
        if ( isempty(ResegState) || isempty(bResegPaused) )
            return;
        end
        
        if ( bResegPaused )
            return;
        end
    end
    
    Figures.time = tEnd;
    UI.DrawTree(ResegState.primaryTree);
    UI.DrawCells();
    
    bFinished = 1;
end
