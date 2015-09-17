function [localLabels, revLocalLabels] = GetLocalTreeLabels(familyID)
    global CellFamilies CellTracks
    
    localLabels = containers.Map('KeyType', 'uint32', 'ValueType', 'any');
    revLocalLabels = containers.Map('KeyType', 'char', 'ValueType', 'uint32');
    trackHeights = Families.ComputeTrackHeights(familyID);
    
    rootTrackID = CellFamilies(familyID).rootTrackID;
    
    numTracks = length(CellFamilies(familyID).tracks);
    
    visitIdx = 1;
    travQueue = rootTrackID;
    while ( ~isempty(travQueue) )
        curTrackID = travQueue(1);
        travQueue = travQueue(2:end);
        
        childTracks = CellTracks(curTrackID).childrenTracks;
        
        if ( ~isempty(childTracks) )
            childHeights(1) = trackHeights(childTracks(1));
            childHeights(2) = trackHeights(childTracks(2));
            
            [srtHeight travOrder] = sort(childHeights, 'descend');
            
            travQueue = [travQueue childTracks(travOrder)];
        end
        
        if ( visitIdx == 1 )
            localLabels(curTrackID) = num2str(curTrackID);
            revLocalLabels(num2str(curTrackID)) = curTrackID;
        else
            alphaLabel = AlphaLocal(visitIdx);
            localLabels(curTrackID) = alphaLabel;
            revLocalLabels(alphaLabel) = curTrackID;
        end
        visitIdx = visitIdx + 1;
    end
end

% Convert the index to a letter -- A..Z, AA, AB..ZZ, AAA..ZZZ, ...
function res = AlphaLocal(label)
    label = label - 1;
    if label <= 0, return, end;
    
    res = '';
    while 1
        label = label - 1;
        digit = mod(label, 26);
        c = char(digit + 'A');
        res = [c res];
        label = floor(label/26);
        if label == 0
            break
        end
    end
end