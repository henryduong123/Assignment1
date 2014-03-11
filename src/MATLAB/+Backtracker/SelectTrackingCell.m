function SelectTrackingCell(trackID,time, bForceUpdate)
    global bDirty Figures CellTracks SelectStruct BackSelectHulls
    
    if ( ~exist('bForceUpdate','var') )
        bForceUpdate = false;
    end
    
    familyID = [];
    
    SelectStruct.editingHullID = [];
    SelectStruct.selectedTrackID = [];
    SelectStruct.selectCosts = [];
    SelectStruct.selectPath = [];
    
    if ( ~isempty(trackID) )
        selectHullID = Tracks.GetHullID(time,trackID);
        if ( selectHullID > 0 )
            SelectStruct.editingHullID = selectHullID;
            BackSelectHulls = union(BackSelectHulls,SelectStruct.editingHullID);

            [SelectStruct.selectCosts SelectStruct.selectPath] = buildSelectTree(trackID);
            SelectStruct.selectedTrackID = trackID;
            
            bDirty = true;
        end
        
        familyID = CellTracks(trackID).familyID;
    end
    
    % Update backtrack hulls before DrawCell call
    Backtracker.UpdateBacktrackHulls();
    
    if ( bForceUpdate )
        % Force redraw of family because a track edit has occurred
        Figures.tree.familyID = familyID;
        Backtracker.DrawTree();
    else
        % Allow drawtree to skip (if familyID is already current)
        Backtracker.DrawTree(familyID);
    end
    
    
    Backtracker.DrawCells();
    
    Backtracker.UpdateTimeLine();
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
    trackHeights = Backtracker.ComputeTrackHeights(rootTrackID);
    edges = costTraverseTree(rootTrackID, 0, trackHeights);
    
%     edges = zeros(0,3);
%     for i=1:length(trackList)
%         edgeTracks = CellTracks(trackList(i)).parentTrack;
%         edgeTracks = [edgeTracks CellTracks(trackList(i)).childrenTracks];
%         
%         for j=1:length(edgeTracks)
%             startID = trackList(i);
%             endID = edgeTracks(j);
%             edgeCost = abs(double(trackHeights(endID)) - double(trackHeights(startID)));
%             
%             edges = [edges; startID endID edgeCost];
%             edges = [edges; endID startID edgeCost];
%         end
%     end
    
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
