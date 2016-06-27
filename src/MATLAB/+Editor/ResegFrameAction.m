% [historyAction bFinished] = ResegFrameAction(t, tMax, viewLims)
% Edit Action:
% 
% Resegment a single frame

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


function [historyAction bFinished] = ResegFrameAction(t, tMax, viewLims)
    global ResegState CellFamilies
    
    bFinished = false;
    
    preserveTracks = [CellFamilies(ResegState.preserveFamilies).tracks];
    newPreserveTracks = Segmentation.ResegFromTree.FixupSingleFrame(t, preserveTracks, tMax, viewLims);

    ResegState.currentTime = t+1;
    
    historyAction.action = 'Push';
    historyAction.arg = t;
end