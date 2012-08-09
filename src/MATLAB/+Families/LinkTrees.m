function [iterations totalTime] = LinkTrees(families)
    global CellFamilies CellTracks
    
    iterations = 0;
    
    rootTrackIDs = [CellFamilies(families).rootTrackID];
    
    % Use changelabel to try and extend tracks back to first frame
    newRootTracks = [];
    backTracks = rootTrackIDs([CellTracks(rootTrackIDs).startTime] ~= 1);
    for i=1:length(backTracks)
        newRootTracks = [newRootTracks linkTreeBack(backTracks(i))];
    end
    
    rootTrackIDs = unique(getRootTracks(union(rootTrackIDs,newRootTracks)));
    
    % Try to Push/reseg
    totalTime = 0;
    maxPushCount = 10;
    for i=1:maxPushCount
    	[assignExt findTime extTime] = Families.LinkTreesForward(rootTrackIDs);
%         LogAction(['Tree inference step ' num2str(i)],[assignExt findTime extTime],[]);
        totalTime = totalTime + findTime + extTime;
        
        iterations = i;
        
        if ( assignExt == 0 )
            break;
        end
    end
    
%     LogAction('Completed Tree Inference', [i totalTime],[]);
end

function newroot = linkTreeBack(rootTrack)
    global CellTracks
    
    costMatrix = Tracker.GetCostMatrix();
    
    curTrack = rootTrack;
    while ( CellTracks(curTrack).startTime > 1 )
        curHull = CellTracks(curTrack).hulls(1);
        prevHulls = find(costMatrix(:,curHull) > 0);
        
        if ( isempty(prevHulls) )
            break;
        end
        
        [bestCost bestIdx] = min(costMatrix(prevHulls,curHull));
        prevTrack = Hulls.GetTrackID(prevHulls(bestIdx));
        
        Tracks.ChangeLabel(curTrack, prevTrack);
        curTrack = getRootTracks(prevTrack);
    end
    
    newroot = curTrack;
end

function rootTracks = getRootTracks(tracks)
    global CellTracks CellFamilies
    
    rootTracks = [];
    for i=1:length(tracks)
        if ( isempty(CellTracks(tracks(i)).startTime) )
            continue;
        end
        
        familyID = CellTracks(tracks(i)).familyID;
        rootTracks = [rootTracks CellFamilies(familyID).rootTrackID];
    end
end