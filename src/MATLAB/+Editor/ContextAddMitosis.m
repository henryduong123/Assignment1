% ContextAddMitosis(trackID, siblingTrack, time)

% ChangeLog:
% EW 6/8/12 created
function ContextAddMitosis(trackID, siblingTrack, time)
global CellTracks Figures

if(siblingTrack>length(CellTracks) || isempty(CellTracks(siblingTrack).hulls))
    msgbox([num2str(siblingTrack) ' is not a valid cell'],'Not a valid cell','error');
    return
end
if(CellTracks(siblingTrack).endTime<time || siblingTrack==trackID)
    msgbox([num2str(siblingTrack) ' is not a valid sister cell'],'Not a valid sister cell','error');
    return
end
if(CellTracks(trackID).startTime>time)
    msgbox([num2str(trackID) ' starts after ' num2str(siblingTrack)],'Not a valid daughter cell','error');
    return
end
if(~isempty(Tracks.GetTimeOfDeath(siblingTrack)) && Tracks.GetTimeOfDeath(siblingTrack)<=time)
    msgbox(['Cannot attach a cell to cell ' num2str(siblingTrack) ' beacuse it is dead at this time'],'Dead Cell','help');
    return
end
if(~isempty(Tracks.GetTimeOfDeath(trackID)) && Tracks.GetTimeOfDeath(trackID)<=time)
    msgbox(['Cannot attach a cell to cell ' num2str(trackID) ' beacuse it is dead at this time'],'Dead Cell','help');
    return
end

% if the sibling has history get rid of it
if (CellTracks(siblingTrack).startTime<time)
    siblingTrack = Families.RemoveFromTreePrune(siblingTrack,time);
end

% if both tracks are starting on this frame see who the parent should be
% and then merge the track with the parent
if(CellTracks(siblingTrack).startTime==time && CellTracks(trackID).startTime==time)
    valid = 0;
    while(~valid)
        answer = inputdlg({'Enter parent of these daughter cells '},'Parent',1,{''});
        if(isempty(answer)),return,end
        parentTrack = str2double(answer(1));
        
        if(CellTracks(parentTrack).startTime>=time || isempty(CellTracks(parentTrack).hulls) ||...
                (~isempty(Tracks.GetTimeOfDeath(parentTrack)) && Tracks.GetTimeOfDeath(parentTrack)<=time))
            choice = questdlg([num2str(parentTrack) ' is an invalid parent for these cells, please choose another'],...
                'Not a valid parent','Enter a different parent','Cancel','Cancel');
            switch choice
                case 'Cancel'
                    return
            end
        else
            valid = 1;
        end
    end
    
    droppedTracks = Tracks.ChangeLabel(trackID,parentTrack);
    trackID = parentTrack;
end

try
    Tracker.GraphEditAddMitosis(trackID, siblingTrack, time);
    droppedTracks = Families.AddMitosis(siblingTrack,trackID);
    Editor.History('Push');
catch errorMessage
    Error.ErrorHandling(['AddMitosis(' num2str(siblingTrack) ' ' num2str(trackID) ' ) -- ' errorMessage.message],errorMessage.stack);
    return
end

Error.LogAction(['Changed parent of ' num2str(trackID) ' and ' num2str(siblingTrack)]);

UI.DrawTree(Figures.tree.familyID);
UI.DrawCells();
end

