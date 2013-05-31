% ContextAddMitosis(trackID, siblingTrack, time)

% ChangeLog:
% EW 6/8/12 created
function ContextAddMitosis(trackID, siblingTrack, time)
global CellTracks CellFamilies Figures

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

bOverrideLock = 0;
bLocked = Helper.CheckLocked([trackID siblingTrack]);
if ( any(bLocked) )
    lockedList = [];
    if ( bLocked(1) )
        lockedList = CellFamilies(CellTracks(trackID).familyID).rootTrackID;
    end
    if ( bLocked(2) )
        lockedList = [lockedList CellFamilies(CellTracks(siblingTrack).familyID).rootTrackID];
    end
    
    resp = questdlg(['This edit will affect locked tree(s) ' num2str(lockedList) '. Do you wish to continue?'], 'Warning: Locked Tree', 'Continue', 'Cancel', 'Cancel');
    if ( strcmpi(resp,'Cancel') )
        return;
    end
    bOverrideLock = 1;
end
leftChildTrack = [];

% if both tracks are starting on this frame see who the parent should be
% and then merge the track with the parent
if(CellTracks(trackID).startTime==time)
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
        elseif ( ~bOverrideLock && Helper.CheckLocked(parentTrack) )
            rootTrack = CellFamilies(CellTracks(parentTrack).familyID).rootTrackID;
            resp = questdlg(['This edit will affect locked tree(s) ' num2str(rootTrack) '. Do you wish to continue?'], 'Warning: Locked Tree', 'Continue', 'Cancel', 'Cancel');
            if ( strcmpi(resp,'Cancel') )
                return;
            end
            
            valid = 1;
        else
            valid = 1;
        end
    end
    
    leftChildTrack = trackID;
    trackID = parentTrack;
end

bErr = Editor.ReplayableEditAction(@Editor.AddMitosisAction, trackID,leftChildTrack,siblingTrack,time);
if ( bErr )
    return;
end

Error.LogAction(['Added ' num2str(siblingTrack) ' as sibling to ' num2str(trackID) ' at time t=' num2str(time)]);

Figures.tree.familyID = CellTracks(trackID).familyID;
UI.DrawTree(Figures.tree.familyID);
UI.DrawCells();
end

