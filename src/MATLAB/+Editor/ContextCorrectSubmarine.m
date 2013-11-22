% ContextCorrectSubmarine.m - Context menu callback function for correcting
% missed "submarines", i.e. when the cell dives beneath the surface and
% reappears several frames later

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     Copyright 2012 Andrew Cohen, Eric Wait, Mark Winter and Walt
%     Mankowski
%
%     This file is part of LEVer - the tool for stem cell lineaging. See
%     https://pantherfile.uwm.edu/cohena/www/LEVer.html for details
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

function ContextCorrectSubmarine(time,trackID)
    global CellTracks CellHulls

    answer = inputdlg({'Enter New Label', 'Enter last visible time'},'New Label',1,{num2str(trackID), num2str(time)});
    if(isempty(answer)),return,end;
    newTrackID = str2double(answer(1));
    lastTime = str2double(answer(2));

    if(isempty(CellTracks(newTrackID).hulls))
        warn = sprintf('Track %d does not exist, cannot change',newTrackID);
        warndlg(warn);
        return
    end
    
    % compute a box to look for subroutines
    curHull = CellTracks(newTrackID).hulls(1);
    fromHull = CellTracks(newTrackID).hulls(length(CellTracks(newTrackID).hulls));
    toHull = CellTracks(trackID).hulls(1);
    
    fromCoM = CellHulls(fromHull).centerOfMass;
    toCoM = CellHulls(toHull).centerOfMass;
    deltaCoM = (toCoM - fromCoM)/(time - lastTime);
    
    minCoMX = floor(min(fromCoM(1), toCoM(1))) - 25;
    minCoMY = floor(min(fromCoM(2), toCoM(2))) - 25;
    maxCoMX = ceil(max(fromCoM(1), toCoM(1))) + 25;
    maxCoMY = ceil(max(fromCoM(2), toCoM(2))) + 25;
    
    % for each frame in between, crop that part of the image
%    for t=lastTime+1:time-1
    for t=lastTime:time
        filename = Helper.GetFullImagePath(t);
        img = Helper.LoadIntensityImage(filename);
        fullSize = size(img);
        img = img(minCoMX:maxCoMX, minCoMY:maxCoMY);
        figure;
        colormap(gray);
        imagesc(img);
        
        % draw a circle around where the CoM would be if it moved evenly
        idx = t - lastTime;
        CoM = fromCoM + deltaCoM * idx;
%         tmp = [CoM(2) CoM(1)];
%         scale = (fullSize(1) - size(img,1)) / (fullSize(2) - size(img,2));
%         
%         tmp = tmp./fullSize.*size(img); % rescale to these bounds
%         CoM = [tmp(2) tmp(1)]
        CoM = CoM-[minCoMX minCoMY];
        circle([CoM(2) CoM(1)], 10, 1000, ':y');
        
        % try to run a Circle Hough Transform on the image
        [bw] = Segmentation.Michel(1-img, [3 3]);
        [centers, radii, metric] = imfindcircles(bw, [10 20]);
        viscircles(centers, radii, 'EdgeColor', 'b');
        
        %wehi_segment(img);
        
        %figure;
        colormap(gray);
        se = strel('disk', 8);
        img = 1-img;
        newImg = imopen(img, se);
%        newImg = imerode(img, se);
%        newImg = stdfilt(img);

%        [bw] = Segmentation.Michel(img, [3 3]);
%        newImg = bwmorph(bw, 'skel', Inf);
%        imagesc(bw);
        %imagesc(newImg);
        %wehi_segment(newImg);
    end

    bErr = Editor.ReplayableEditAction(@Editor.ChangeLabelAction, trackID,newTrackID,time);
    if ( bErr )
        return;
    end
    
    Error.LogAction('ChangeLabel',trackID,newTrackID);

    newTrackID = Hulls.GetTrackID(curHull);
    UI.DrawTree(CellTracks(newTrackID).familyID);
    UI.DrawCells();
end

function wehi_segment(img)
    [bw] = Segmentation.Michel(img, [3 3]);
    [r c] = find(bw);
    hold on;
    plot(c,r,'.r');
    
    [L num] = bwlabel(bw);
    bestCount=-1;
    bestN = -1;
    for n=1:num
        [r c] = find(L==n);
        if length(r) < 15, continue, end
        if length(r) > bestCount
            bestN = n;
            bestCount = length(r);
        end
    end
    if bestCount > 0
        [r c] = find(L==bestN);
        ch = Helper.ConvexHull(c,r);
        plot(c(ch), r(ch), '-g');
    end
    
    hold off;
end

function H=circle(center,radius,NOP,style)
%---------------------------------------------------------------------------------------------
% H=CIRCLE(CENTER,RADIUS,NOP,STYLE)
% This routine draws a circle with center defined as
% a vector CENTER, radius as a scaler RADIS. NOP is 
% the number of points on the circle. As to STYLE,
% use it the same way as you use the rountine PLOT.
% Since the handle of the object is returned, you
% use routine SET to get the best result.
%
%   Usage Examples,
%
%   circle([1,3],3,1000,':'); 
%   circle([2,4],2,1000,'--');
%
%   Zhenhai Wang <zhenhai@ieee.org>
%   Version 1.00
%   December, 2002
%---------------------------------------------------------------------------------------------

if (nargin <3),
 error('Please see help for INPUT DATA.');
elseif (nargin==3)
    style='b-';
end;
THETA=linspace(0,2*pi,NOP);
RHO=ones(1,NOP)*radius;
[X,Y] = pol2cart(THETA,RHO);
X=X+center(1);
Y=Y+center(2);
hold on;
H=plot(X,Y,style);
%axis square;
end