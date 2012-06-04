function UnitTestMexDijkstra(costGraph, numIters)

    UI.Progressbar(0);
    % Test single edge removal
    mexDijkstra('initGraph', costGraph);
    numIters = min(numIters, nnz(costGraph));
    testCostGraph = costGraph;
    for i=1:numIters
        [rcm, ccm] = find(testCostGraph > 0);
%         graphInd = sub2ind(size(testCostGraph), rcm, ccm);
        
        rndidx = randi(length(rcm),1);
        testCostGraph(rcm(rndidx),ccm(rndidx)) = 0;
        
        mexDijkstra('removeEdges', rcm(rndidx),ccm(rndidx));
        UI.Progressbar((i/numIters) / 3);
    end
    Tracker.CheckMEXSynch(testCostGraph);
    
    % Test out edge removal
    mexDijkstra('initGraph', costGraph);
    testCostGraph = costGraph;
    for i=1:numIters
        [rcm, ccm] = find(testCostGraph > 0);
%         graphInd = sub2ind(size(testCostGraph), rcm, ccm);

        if ( isempty(rcm) )
            break;
        end
        
        rndidx = randi(length(rcm),1);
        testCostGraph(rcm(rndidx),:) = 0;
        
        mexDijkstra('removeEdges', rcm(rndidx),[]);
        UI.Progressbar((i/numIters) / 3 + 1/3);
    end
    Tracker.CheckMEXSynch(testCostGraph);
    
    % Test in edge removal
    mexDijkstra('initGraph', costGraph);
    testCostGraph = costGraph;
    for i=1:numIters
        [rcm, ccm] = find(testCostGraph > 0);
%         graphInd = sub2ind(size(testCostGraph), rcm, ccm);
        
        rndidx = randi(length(rcm),1);
        testCostGraph(:,ccm(rndidx)) = 0;
        
        mexDijkstra('removeEdges', [],ccm(rndidx));
        UI.Progressbar((i/numIters) / 3 + 2/3);
    end
    Tracker.CheckMEXSynch(testCostGraph);
    UI.Progressbar(1);
end