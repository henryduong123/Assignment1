function CreateMitosis(trackID, dirFlag, time, startPt,endPt)
    global bDirty
    
    linePoints = [startPt; endPt];
    linePoints = clipToImage(linePoints);
    
    % Find or create hulls to define mitosis event
    childHulls = Segmentation.MitosisEditor.FindChildrenHulls(linePoints, time);
    parentHull = Segmentation.MitosisEditor.FindParentHull(childHulls, linePoints, time-1);
    
    parentTrackID = Hulls.GetTrackID(parentHull);
    if ( dirFlag < 0 )
        parentTrackID = Backtracker.TearoffHull(parentTrackID, time-1);
    elseif ( parentTrackID ~= trackID )
        parentTrackID = Backtracker.TearoffHull(parentTrackID, time-1);
        Tracks.ChangeTrackID(parentTrackID, trackID, time-1);
    end
    
    chkTrackID = Hulls.GetTrackID(childHulls(1));
    if ( chkTrackID ~= parentTrackID )
        chkTrackID = Backtracker.TearoffHull(chkTrackID, time);
        Tracks.ChangeLabel(chkTrackID, parentTrackID, time);
    end
    
    if ( dirFlag < 0 )
        Tracks.ChangeLabel(trackID, parentTrackID, time+1);
    end
    
    chkTrackID = Hulls.GetTrackID(childHulls(2));
    newTrackID = Backtracker.TearoffHull(chkTrackID, time);
    Families.AddMitosis(newTrackID, parentTrackID, time);
    
    Backtracker.UpdateBacktrackInfo();
    
    bDirty = true;
end

function newPoints = clipToImage(linePoints)
    global CONSTANTS
    
    newPoints = linePoints;
    newPoints(:,1) = min(newPoints(:,1), repmat(CONSTANTS.imageSize(2),size(linePoints,1),1));
    newPoints(:,2) = min(newPoints(:,2), repmat(CONSTANTS.imageSize(1),size(linePoints,1),1));
    
    newPoints(:,1) = max(newPoints(:,1), repmat(1,size(linePoints,1),1));
    newPoints(:,2) = max(newPoints(:,2), repmat(1,size(linePoints,1),1));
end
