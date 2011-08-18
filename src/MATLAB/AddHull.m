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

if(num>6)
    msgbox('Please limit number of new cells to 6','Add Hull Limit','help');
    return
end

[hullID trackID] = GetClosestCell(1);
clickPt = get(gca,'CurrentPoint');

if ( ~CHullContainsPoint(clickPt(1,1:2), CellHulls(hullID)) )
    trackID = [];
end

if(~isempty(trackID))
    % Try to split the existing hull    
    if ( num > 1 )
        try
            newTracks = SplitHull(hullID,num);
            if(isempty(newTracks))
                msgbox(['Unable to split ' num2str(trackID) ' any further in this frame'],'Unable to Split','help','modal');
                return
            end
            History('Push');
        catch errorMessage
            try
                ErrorHandeling(['SplitHull(' num2str(hullID) ' ' num2str(num) ') -- ' errorMessage.message], errorMessage.stack);
                return
            catch errorMessage2
                 fprintf('%s',errorMessage2.message);
                return
            end
        end
        LogAction('Split cell',trackID,[trackID newTracks]);
    end
elseif ( num<2 )
    % Try to run local segmentation and find a hull we missed or place a
    % point-hull at least
    try
        newTrack = AddNewSegmentHull(clickPt(1,1:2));
        History('Push');
    catch errorMessage
        try
            ErrorHandeling(['AddNewSegmentHull(clickPt(1,1:2)) -- ' errorMessage.message], errorMessage.stack);
            return
        catch errorMessage2
            fprintf('%s',errorMessage2.message);
            return
        end
    end
    LogAction('Added cell',newTrack);
else
    return;
end

DrawTree(Figures.tree.familyID);
DrawCells();
end
