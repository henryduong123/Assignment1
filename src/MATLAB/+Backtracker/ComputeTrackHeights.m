function trackHeights = ComputeTrackHeights(rootTrackID)
    trackHeights = containers.Map('KeyType', 'uint32', 'ValueType', 'uint32');
    
	recursiveTrackHeights(rootTrackID, trackHeights); 
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
