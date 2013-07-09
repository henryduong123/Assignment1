function newPreserveTracks = LinkupEdges(edges, preserveTracks)
    global CellTracks
    
    targetParents = [];
    relinkList = {};
    
    for i=1:size(edges,1)
        
        if ( edges(i,2) == 0 )
%             error('Unable to reassign track with long or short edge, structure will be affected');
            continue;
        end
        
        targetIdx = find(targetParents == Hulls.GetTrackID(edges(i,1)));
        if ( isempty(targetIdx) )
            targetParents = [targetParents; Hulls.GetTrackID(edges(i,1))];
            relinkList = [relinkList; {Hulls.GetTrackID(edges(i,2))}];
        else
            relinkList{targetIdx} = [relinkList{targetIdx} Hulls.GetTrackID(edges(i,2))];
        end
    end
    
    newPreserveTracks = [];
    for i=1:length(targetParents)
        parentTrack = targetParents(i);
        childrenTracks = relinkList{i};
        
        childrenTimes = [CellTracks(childrenTracks).startTime];
        if ( length(childrenTimes) > 1 )
            Families.ReconnectParentWithChildren(parentTrack, childrenTracks);
            newPreserveTracks = [newPreserveTracks childrenTracks];
        else
            Tracks.ChangeLabel(childrenTracks, parentTrack, childrenTimes);
            newPreserveTracks = [newPreserveTracks parentTrack];
        end
    end
    
    newPreserveTracks = setdiff(newPreserveTracks, preserveTracks);
end
