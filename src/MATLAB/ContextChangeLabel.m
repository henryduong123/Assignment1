%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     This file is part of LEVer.exe
%     (C) 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ContextChangeLabel(time,trackID)
%context menu callback function


global CellTracks HashedCells CellFamilies

newTrackID = inputdlg('Enter New Label','New Label',1,{num2str(trackID)});
if(isempty(newTrackID)),return,end;
newTrackID = str2double(newTrackID(1));

%error checking
if(0>=newTrackID)
    msgbox(['New label of ' num2str(newTrackID) ' is not a valid number'],'Change Label','warn');
    return
elseif(length(CellTracks)<newTrackID || isempty(CellTracks(newTrackID).hulls))
    choice = questdlg(['Changing ' num2str(trackID) ' to ' num2str(newTrackID) ' will have the same effect as Remove From Tree'],...
        'Remove From Tree?','Continue','Cancel','Cancel');
    switch choice
        case 'Continue'
            newLabel = length(CellTracks) + 1;
            try
                ContextRemoveFromTree(time,trackID);
                History('Push');
            catch errorMessage
                try
                    ErrorHandeling(['ContextRemoveFromTree(' num2str(time) ' ' num2str(trackID) ' ) -- ' errorMessage.message],errorMessage.stack);
                    return
                catch errorMessage2
                    fprintf('%s',errorMessage2.message);
                    return
                end
            end
            msgbox(['The new cell label is ' num2str(newLabel)],'Remove From Tree','help');
            return
        case 'Cancel'
            return
    end
elseif(~isempty(find([HashedCells{time}.trackID]==newTrackID,1)))
%     choice = questdlg(['Label ' num2str(newTrackID) ' exist on this frame. Would you like these labels to swap from here forward or just this frame?'],...
%         'Swap Labels?','Forward','This Frame','Cancel','Cancel');
%     switch choice
%         case 'Forward'
            try
                GraphEditSetEdge(time,trackID,newTrackID);
                GraphEditSetEdge(time,newTrackID,trackID);
                SwapTrackLabels(time,trackID,newTrackID);
                History('Push');
            catch errorMessage
                try
                    ErrorHandeling(['SwapTrackLabels(' num2str(time) ' ' num2str(trackID) ' ' num2str(newTrackID) ') -- ' errorMessage.message],errorMessage.stack);
                    return
                catch errorMessage2
                    fprintf('%s',errorMessage2.message);
                    return
                end
            end
            LogAction('Swapped Labels',trackID,newTrackID);
%         case 'This Frame'
%             History('Push');
%             try
%                 SwapHulls(time,trackID,newTrackID);
%             catch errorMessage
%                 try
%                     ErrorHandeling(['SwapHulls(' num2str(time) ' ' num2str(trackID) num2str(newTrackID) ') -- ' errorMessage.message],errorMessage.stack);
%                 catch errorMessage2
%                     fprintf(errorMessage2.message);
%                     return
%                 end
%             end
%         case 'Cancel'
%             return
%     end
elseif(isempty(CellTracks(trackID).parentTrack) && isempty(CellTracks(trackID).childrenTracks) && 1==length(CellTracks(trackID).hulls))
    hullID = CellTracks(trackID).hulls(1);
    try
        GraphEditSetEdge(CellTracks(trackID).startTime,newTrackID,trackID);
        GraphEditSetEdge(CellTracks(trackID).startTime+1,trackID,newTrackID);
        AddSingleHullToTrack(trackID,newTrackID);
        History('Push');
    catch errorMessage
        try
            ErrorHandeling(['AddSingleHullToTrack(' num2str(trackID) ' ' num2str(newTrackID) ') -- ' errorMessage.message],errorMessage.stack);
            return
        catch errorMessage2
            fprintf('%s',errorMessage2.message);
            return
        end
    end
    LogAction('Added hull to track',hullID,newTrackID);
elseif(~isempty(CellTracks(trackID).parentTrack) && CellTracks(trackID).parentTrack==newTrackID)
    try
        GraphEditMoveMitosis(time,trackID);
        MoveMitosisUp(time,trackID);
        History('Push');
    catch errorMessage
        try
            ErrorHandeling(['MoveMitosisUp(' num2str(time) ' ' num2str(trackID) ') -- ' errorMessage.message],errorMessage.stack);
            return
        catch errorMessage2
            fprintf('%s',errorMessage2.message);
            return
        end
    end
    LogAction('Moved Mitosis Up',trackID,newTrackID);
elseif(~isempty(CellTracks(newTrackID).parentTrack) && CellTracks(newTrackID).parentTrack==trackID)
    try
        GraphEditMoveMitosis(time,newTrackID);
        MoveMitosisUp(time,newTrackID);
        History('Push');
    catch errorMessage
        try
            ErrorHandeling(['MoveMitosisUp(' num2str(time) ' ' num2str(newTrackID) ') -- ' errorMessage.message],errorMessage.stack);
            return
        catch errorMessage2
            fprintf('%s',errorMessage2.message);
            return
        end
    end
    LogAction('Moved Mitosis Up',newTrackID,trackID);
else
    try
        %TODO: This edit graph update may need to more complicated to truly
        %capture user edit intentions.
        GraphEditSetEdge(time,newTrackID,trackID);
        ChangeLabel(time,trackID,newTrackID);
        History('Push');
    catch errorMessage
        try
            ErrorHandeling(['ChangeLabel(' num2str(time) ' ' num2str(trackID) ' ' num2str(newTrackID) ') -- ' errorMessage.message],errorMessage.stack);
            return
        catch errorMessage2
            fprintf('%s',errorMessage2.message);
            return
        end
    end
    LogAction('ChangeLabel',trackID,newTrackID);
end

curHull = CellTracks(newTrackID).hulls(1);

ProcessNewborns(1:length(CellFamilies),length(HashedCells));

newTrackID = GetTrackID(curHull);
DrawTree(CellTracks(newTrackID).familyID);
DrawCells();
end
