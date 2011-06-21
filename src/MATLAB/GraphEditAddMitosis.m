%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     This file is part of LEVer.exe
%     (C) 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function GraphEditAddMitosis(time, trackID, siblingTrackID)
    global CellTracks GraphEdits Costs
    
    parentHash = time - CellTracks(trackID).startTime;
    siblingHash = time - CellTracks(siblingTrackID).startTime + 1;
    
    if ( parentHash < 1 || parentHash+1 > length(CellTracks(trackID).hulls) )
        return;
    end
    if ( siblingHash < 1 || siblingHash > length(CellTracks(trackID).hulls) )
        return;
    end
    
    parentHull = CellTracks(trackID).hulls(parentHash);
    childHull = CellTracks(trackID).hulls(parentHash+1);
    
    siblingHull = CellTracks(siblingTrackID).hulls(siblingHash);
    
    if ( parentHull == 0 || childHull == 0 || siblingHull == 0 )
        return;
    end
    
    GraphEdits(parentHull,:) = 0;
    GraphEdits(:,childHull) = 0;
    GraphEdits(:,siblingHull) = 0;
    
    cChild = Costs(parentHull,childHull);
    if ( cChild == 0 )
        cChild = Inf;
    end
    
    cSibling = Costs(parentHull,siblingHull);
    if ( cSibling == 0 )
        cSibling = Inf;
    end
    
    if ( cChild < cSibling )
        GraphEdits(parentHull,childHull) = 1;
        GraphEdits(parentHull,siblingHull) = 2;
    else
        GraphEdits(parentHull,childHull) = 2;
        GraphEdits(parentHull,siblingHull) = 1;
    end
end