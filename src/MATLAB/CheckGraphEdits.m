% Depending on tracking direction add and remove to/from hulls so that all
% user graph edits are accounted for within the tracker.
function [trackHulls,nextHulls] = CheckGraphEdits(dir, fromHulls, toHulls)
    global GraphEdits CellHulls
    
    nextHulls = toHulls;
    trackHulls = fromHulls;
    
    if ( isempty(toHulls) )
        return;
    end
    
    if ( dir > 0 )
        inEdits = GraphEdits;
    else
        inEdits = GraphEdits';
    end
    
    if ( dir > 0 )
        needTrackHulls = find(any(inEdits(:,toHulls) == 1,2));
        needNextHulls = find(any(inEdits(fromHulls,:) == 1,1));
        
        editedFromHulls = fromHulls(any(inEdits(fromHulls,:) > 0,2));
        editedToHulls = toHulls(any(inEdits(:,toHulls) > 0,1));
        
        trackHulls = setdiff(trackHulls, editedFromHulls);
        nextHulls = setdiff(nextHulls, editedToHulls);
    else
        needNextHulls = [];
        needTrackHulls = find(any(inEdits(:,toHulls) > 0,2));
        editedFromHulls = fromHulls(any(inEdits(fromHulls,:) > 0,2));
        trackHulls = setdiff(trackHulls, editedFromHulls);
    end
    
    trackHulls = union(trackHulls,needTrackHulls);
    nextHulls = union(nextHulls,needNextHulls);
    
    bDeleted = find([CellHulls(trackHulls).deleted]);
    trackHulls(bDeleted)=[];
    
    bDeleted = find([CellHulls(nextHulls).deleted]);
    nextHulls(bDeleted)=[];
    
    
end

