function trackHeights = ComputeTrackHeights(rootTrackID)
    global CellFamilies
    
    trackHeights = containers.Map('KeyType', 'uint32', 'ValueType', 'uint32');
    roots = [];
    if isfield(CellFamilies, 'extFamily')
        family = CellFamilies(rootTrackID);
        if isempty(family.extFamily)
            roots = [rootTrackID];
        else
            roots = family.extFamily;
        end
    else
        roots = [rootTrackID];
    end

    for i=1:length(roots)
        recursiveTrackHeights(roots(i), trackHeights); 
    end
end

function height = recursiveTrackHeights(trackID, trackHeights)
    global CellTracks
    
    if(~isempty(CellTracks(trackID).childrenTracks))
        leftHeight = recursiveTrackHeights(CellTracks(trackID).childrenTracks(1), trackHeights);
        rightHeight = recursiveTrackHeights(CellTracks(trackID).childrenTracks(2), trackHeights);
        
        height = 1 + max(leftHeight, rightHeight);
    else
        % leaf node
        height = 1;
    end
    
    trackHeights(trackID) = height;
end
