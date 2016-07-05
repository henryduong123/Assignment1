% historyAction = CreateMitosisAction(treeID, time, startPoint, endPoint)
% Edit Action:
% 
% Create user identified mitosis events and add to current tree.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     Copyright 2011-2016 Andrew Cohen
%
%     This file is part of LEVer - the tool for stem cell lineaging. See
%     http://n2t.net/ark:/87918/d9rp4t for details
% 
%     LEVer is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
%     LEVer is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
% 
%     You should have received a copy of the GNU General Public License
%     along with LEVer in file "gnu gpl v3.txt".  If not, see 
%     <http://www.gnu.org/licenses/>.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function historyAction = CreateMitosisAction(trackID, dirFlag, time, linePoints)
    global CellTracks
    
    if ( time < 2 )
        error('Mitosis event cannot be defined in the first frame');
    end
    
    treeID = CellTracks(trackID).familyID;
    linePoints = clipToImage(linePoints);
    
    % Find or create hulls to define mitosis event
    childHulls = Segmentation.MitosisEditor.FindChildrenHulls(linePoints, time);
    parentHull = Segmentation.MitosisEditor.FindParentHull(childHulls, linePoints, time-1);
    
    chkDropHull = Helper.GetNearestTrackHull(trackID, time+1,+1);
    
    parentTrackID = Hulls.GetTrackID(parentHull);
    if ( parentTrackID ~= trackID )
        parentTrackID = Tracks.TearoffHull(parentHull);
        
        Tracks.ChangeTrackID(parentTrackID, trackID, time-1);
    end
    
    chkTrackID = Hulls.GetTrackID(childHulls(1));
    if ( chkTrackID ~= trackID )
        chkTrackID = Tracks.TearoffHull(childHulls(1));
        Tracks.ChangeLabel(chkTrackID, trackID, time);
    end
    
    newTrackID = Tracks.TearoffHull(childHulls(2));
    Families.AddMitosis(newTrackID, trackID, time);
    
    if ( chkDropHull > 0 )
        leftChildTrackID = Hulls.GetTrackID(childHulls(1));
        fixupChildTrackID = Hulls.GetTrackID(chkDropHull);
        Tracks.ChangeLabel(fixupChildTrackID, leftChildTrackID, time+1);
    end
    
    Editor.LogEdit('Mitosis',parentHull,childHulls,true);
    
    Helper.SetTreeLocked(treeID, 1);
    
    historyAction = 'Push';
end

function newPoints = clipToImage(linePoints)
    newPoints = linePoints;
    
    xyImageDims = Metadata.GetDimensions('xy');
    newPoints(:,1) = min(newPoints(:,1), repmat(xyImageDims(1),size(linePoints,1),1));
    newPoints(:,2) = min(newPoints(:,2), repmat(xyImageDims(2),size(linePoints,1),1));
    
    newPoints(:,1) = max(newPoints(:,1), repmat(1,size(linePoints,1),1));
    newPoints(:,2) = max(newPoints(:,2), repmat(1,size(linePoints,1),1));
end

