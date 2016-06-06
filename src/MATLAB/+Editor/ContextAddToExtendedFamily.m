% ContextAddToExtendedFamily.m - Context menu callback function for adding
% a track to an extended family

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

function ContextAddToExtendedFamily(hullIDs)
    global CellFamilies CellTracks Figures

    trackIDs = Hulls.GetTrackID(hullIDs);
    familyIDs = [CellTracks(trackIDs).familyID];

    for i=1:length(familyIDs)
        familyID = familyIDs(i);
        if ~isempty(CellFamilies(familyID).extFamily)
            xfam = CellFamilies(familyID).extFamily;
            if length(xfam) > 1
                warn = sprintf('Track %d is already in an extended family', trackID);
                warndlg(warn);
                return;
            end
        end
    end

    [localLabels, revLocalLabels] = UI.GetLocalTreeLabels(Figures.tree.familyID);
    answer = inputdlg('Enter cell label of family to join','Join Family',1,{num2str(CellFamilies(Figures.tree.familyID).tracks(1))});
    if(isempty(answer)),return,end;
    
    newTrackIDLocal = answer{1};
    newTrackID = UI.LocalToTrack(revLocalLabels, newTrackIDLocal);

    if ( isnan(newTrackID) || newTrackID > length(CellTracks) )
        warn = sprintf('Track %s does not exist.',newTrackIDLocal);
        warndlg(warn);
        return;
    end

    if(isempty(CellTracks(newTrackID).hulls))
        warn = sprintf('Track %s does not exist.',newTrackIDLocal);
        warndlg(warn);
        return
    end
    
    if ( ismember(newTrackID, trackIDs) )
        warn = sprintf('Track %s is one of the selected track(s).', newTrackIDLocal);
        warndlg(warn);
        return;
    end

    newFamilyID = CellTracks(newTrackID).familyID;
    newExtFamily = union(CellFamilies(newFamilyID).extFamily, [familyIDs newFamilyID]);
    [CellFamilies(newExtFamily).extFamily] = deal(newExtFamily);
    
    UI.DrawTree(Figures.tree.familyID);
    UI.DrawCells();
end
