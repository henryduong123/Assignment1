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

function UpdateSegmentationEditsMenu(src,evnt)
    global SegmentationEdits Figures
    
    if ( isempty(SegmentationEdits) || ((isempty(SegmentationEdits.newHulls) || isempty(SegmentationEdits.changedHulls)) && isempty(SegmentationEdits.editTime)) )
%         set(Figures.tree.menuHandles.learnEditsMenu, 'enable', 'off');
%         set(Figures.cells.menuHandles.learnEditsMenu, 'enable', 'off');
        set(Figures.cells.learnButton, 'Visible', 'off');
    else
        pos = get(Figures.cells.handle,'Position');
        position = [pos(3)-120 pos(4)-30 100 20];
        set(Figures.cells.learnButton, 'Visible', 'on','Position',position);
%         set(Figures.tree.menuHandles.learnEditsMenu, 'enable', 'on');
%         set(Figures.cells.menuHandles.learnEditsMenu, 'enable', 'on');
    end
end