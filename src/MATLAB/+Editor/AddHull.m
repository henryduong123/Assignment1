% AddHull.m - Attempt to add or split cell hull into specified number of
% pieces.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     Copyright 2011 Andrew Cohen, Eric Wait and Mark Winter
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

function AddHull(num)
global Figures CellHulls

[hullID trackID] = UI.GetClosestCell(1);
clickPt = get(gca,'CurrentPoint');

clickCoord = clickPt(1,1:2);

if ( ~Hulls.CheckHullsContainsPoint(clickCoord, CellHulls(hullID)) )
    trackID = [];
end

if(~isempty(trackID) && (num > 1))
    % Try to split the existing hull    
    [bErr newTracks] = Editor.ReplayableEditAction(@Editor.SplitCell, hullID,num);
    if ( bErr )
        return;
    end
    
    if ( isempty(newTracks) )
        msgbox(['Unable to split ' num2str(trackID) ' any further in this frame'],'Unable to Split','help','modal');
        return;
    end
    
    Editor.History('Push');
    Error.LogAction('Split cell',trackID,[trackID newTracks]);
    
elseif ( num == 1 )
    % Try to run local segmentation and find a hull we missed or place a
    % point-hull at least
    [bErr newTrack] = Editor.ReplayableEditAction(@Editor.AddNewCell, clickCoord);
    if ( bErr )
        return;
    end
    
    Editor.History('Push');
    Error.LogAction('Added cell',newTrack);
else
    return;
end

UI.DrawTree(Figures.tree.familyID);
UI.DrawCells();
end
