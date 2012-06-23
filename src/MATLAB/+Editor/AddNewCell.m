% [historyAction newTrack] = AddNewCell(clickPoint)
% Edit Action:
% 
% Search for a new segmentation containing the clicked point, if unable to
% find a segmentation result, add a singple point segmentation at
% clickPoint

function [historyAction newTrack] = AddNewCell(clickPoint)
    newTrack = Segmentation.AddNewSegmentHull(clickPoint);
    
    historyAction = 'Push';
end
