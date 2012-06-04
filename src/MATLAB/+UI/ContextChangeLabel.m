% ContextChangeLabel.m - Context menu callback function for changing track
% labels

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

function ContextChangeLabel(time,trackID)

global CellTracks HashedCells CellFamilies

newTrackID = inputdlg('Enter New Label','New Label',1,{num2str(trackID)});
if(isempty(newTrackID)),return,end;
newTrackID = str2double(newTrackID(1));

%error checking
% if(0>=newTrackID)
%     msgbox(['New label of ' num2str(newTrackID) ' is not a valid number'],'Change Label','warn');
%     return
% elseif(length(CellTracks)<newTrackID || isempty(CellTracks(newTrackID).hulls))
%     choice = questdlg(['Changing ' num2str(trackID) ' to ' num2str(newTrackID) ' will have the same effect as Remove From Tree'],...
%         'Remove From Tree?','Continue','Cancel','Cancel');
%     switch choice
%         case 'Continue'
%             newLabel = length(CellTracks) + 1;
%             try
%                 ContextRemoveFromTree(time,trackID);
%                 History('Push');
%             catch errorMessage
%                 try
%                     ErrorHandeling(['ContextRemoveFromTree(' num2str(time) ' ' num2str(trackID) ' ) -- ' errorMessage.message],errorMessage.stack);
%                     return
%                 catch errorMessage2
%                     fprintf('%s',errorMessage2.message);
%                     return
%                 end
%             end
%             msgbox(['The new cell label is ' num2str(newLabel)],'Remove From Tree','help');
%             return
%         case 'Cancel'
%             return
%     end
% elseif(~isempty(find([HashedCells{time}.trackID]==newTrackID,1)))
%     try
%         GraphEditSetEdge(time,trackID,newTrackID);
%         GraphEditSetEdge(time,newTrackID,trackID);
%         SwapTrackLabels(time,trackID,newTrackID);
%         History('Push');
%     catch errorMessage
%         try
%             ErrorHandeling(['SwapTrackLabels(' num2str(time) ' ' num2str(trackID) ' ' num2str(newTrackID) ') -- ' errorMessage.message],errorMessage.stack);
%             return
%         catch errorMessage2
%             fprintf('%s',errorMessage2.message);
%             return
%         end
%     end
%     LogAction('Swapped Labels',trackID,newTrackID);
% elseif(isempty(CellTracks(trackID).parentTrack) && isempty(CellTracks(trackID).childrenTracks) && 1==length(CellTracks(trackID).hulls))
%     hullID = CellTracks(trackID).hulls(1);
%     try
%         GraphEditSetEdge(CellTracks(trackID).startTime,newTrackID,trackID);
%         GraphEditSetEdge(CellTracks(trackID).startTime+1,trackID,newTrackID);
%         AddSingleHullToTrack(trackID,newTrackID);
%         History('Push');
%     catch errorMessage
%         try
%             ErrorHandeling(['AddSingleHullToTrack(' num2str(trackID) ' ' num2str(newTrackID) ') -- ' errorMessage.message],errorMessage.stack);
%             return
%         catch errorMessage2
%             fprintf('%s',errorMessage2.message);
%             return
%         end
%     end
%     LogAction('Added hull to track',hullID,newTrackID);
% elseif(~isempty(CellTracks(trackID).parentTrack) && CellTracks(trackID).parentTrack==newTrackID)
%     try
%         GraphEditMoveMitosis(time,trackID);
%         MoveMitosisUp(time,trackID);
%         History('Push');
%     catch errorMessage
%         try
%             ErrorHandeling(['MoveMitosisUp(' num2str(time) ' ' num2str(trackID) ') -- ' errorMessage.message],errorMessage.stack);
%             return
%         catch errorMessage2
%             fprintf('%s',errorMessage2.message);
%             return
%         end
%     end
%     LogAction('Moved Mitosis Up',trackID,newTrackID);
% elseif(~isempty(CellTracks(newTrackID).parentTrack) && CellTracks(newTrackID).parentTrack==trackID)
%     try
%         GraphEditMoveMitosis(time,newTrackID);
%         MoveMitosisUp(time,newTrackID);
%         History('Push');
%     catch errorMessage
%         try
%             ErrorHandeling(['MoveMitosisUp(' num2str(time) ' ' num2str(newTrackID) ') -- ' errorMessage.message],errorMessage.stack);
%             return
%         catch errorMessage2
%             fprintf('%s',errorMessage2.message);
%             return
%         end
%     end
%     LogAction('Moved Mitosis Up',newTrackID,trackID);
% else
    try
        %TODO: This edit graph update may need to more complicated to truly
        %capture user edit intentions.
        Tracker.GraphEditSetEdge(time,newTrackID,trackID);
        Tracks.ChangeLabel(time,trackID,newTrackID); %TODO fix func call
        UI.History('Push');
    catch errorMessage
        try
            Error.ErrorHandeling(['ChangeLabel(' num2str(time) ' ' num2str(trackID) ' ' num2str(newTrackID) ') -- ' errorMessage.message],errorMessage.stack);
            return
        catch errorMessage2
            fprintf('%s',errorMessage2.message);
            return
        end
    end
    Error.LogAction('ChangeLabel',trackID,newTrackID);
% end

curHull = CellTracks(newTrackID).hulls(1);

Families.ProcessNewborns(1:length(CellFamilies),length(HashedCells));

newTrackID = Tracks.GetTrackID(curHull);
UI.DrawTree(CellTracks(newTrackID).familyID);
UI.DrawCells();
end
