function MitosisSelectTrackingCell(trackID,time, bForceUpdate)
    global Figures CellTracks MitosisEditStruct
    
    if ( ~exist('bForceUpdate','var') )
        bForceUpdate = false;
    end
    
    familyID = [];
    
    MitosisEditStruct.editingHullID = [];
    MitosisEditStruct.selectedTrackID = [];
    MitosisEditStruct.selectCosts = [];
    MitosisEditStruct.selectPath = [];
    
    if ( ~isempty(trackID) )
        selectHullID = Tracks.GetHullID(time,trackID);
        if ( selectHullID > 0 )
            MitosisEditStruct.editingHullID = selectHullID;

            [MitosisEditStruct.selectCosts MitosisEditStruct.selectPath] = buildSelectTree(trackID);
            MitosisEditStruct.selectedTrackID = trackID;
        end
        
        familyID = CellTracks(trackID).familyID;
        
        UI.DrawTree(familyID);
    end
    
    UI.DrawCells();
    UI.UpdateTimeIndicatorLine();
end

function [treeCosts treePath] = buildSelectTree(trackID)
    global CellFamilies CellTracks
    
    treeCosts = [];
    treePath = [];
    if ( isempty(trackID) )
        return;
    end
    
    familyID = CellTracks(trackID).familyID;
    rootTrackID = CellFamilies(familyID).rootTrackID;
    
    trackList = CellFamilies(familyID).tracks;
    trackHeights = Families.ComputeTrackHeights(rootTrackID);
    edges = costTraverseTree(rootTrackID, 0, trackHeights);
    
    treeGraph = sparse(edges(:,1), edges(:,2), edges(:,3), length(CellTracks), length(CellTracks));
    [dist pred] = matlab_bgl.dijkstra_sp(treeGraph, trackID);
    
    chkPred = (pred(trackList).');
    distSign = ones(size(chkPred));
    
    for i=1:length(trackList)
        if ( chkPred(i) > 0 )
            distSign(i) = sign(double(trackHeights(chkPred(i))) - double(trackHeights(trackList(i))));
        end
    end
    
    chkDist = dist(trackList) .* distSign;
    
    treeCosts = containers.Map(uint32(trackList), chkDist);
    treePath = containers.Map(uint32(trackList), uint32(chkPred));
end

function [edges nxtCost] = costTraverseTree(trackID, cost, trackHeights)
    global CellTracks
    
    edges = zeros(0,3);
    if ( isempty(CellTracks(trackID).childrenTracks) )
        nxtCost = cost+1;
        return;
    end
    
    leftChildID = CellTracks(trackID).childrenTracks(1);
    rightChildID = CellTracks(trackID).childrenTracks(2);
    if ( trackHeights(rightChildID) < trackHeights(leftChildID) )
        leftChildID = CellTracks(trackID).childrenTracks(2);
        rightChildID = CellTracks(trackID).childrenTracks(1);
    end
    
    [leftEdges leftCost] = costTraverseTree(leftChildID, cost, trackHeights);
    [rightEdges rightCost] = costTraverseTree(rightChildID, leftCost, trackHeights);
    
    edges = [leftEdges; rightEdges];
    edges = [edges; trackID leftChildID leftCost];
    edges = [edges; leftChildID trackID leftCost];
    
    edges = [edges; trackID rightChildID rightCost];
    edges = [edges; rightChildID trackID rightCost];
    
    nxtCost = 1.1*rightCost+1;
end
