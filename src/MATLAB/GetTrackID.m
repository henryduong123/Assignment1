%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     This file is part of LEVer.exe
%     (C) 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function trackIDs = GetTrackID(hullIDs,time)
%Given a hull ID a track ID will be returned or [] if none found


global CellHulls HashedCells

trackIDs = [];

% if(~exist('time','var'))
for i=1:length(hullIDs)
    if(hullIDs(i)>length(CellHulls))
        continue
    else
        hullTime = CellHulls(hullIDs(i)).time;
        hashedCellIndex = [HashedCells{hullTime}.hullID] == hullIDs(i);
        if(isempty(hashedCellIndex)),continue,end
        trackIDs = [trackIDs HashedCells{hullTime}(hashedCellIndex).trackID];
    end
end
% else
%     if(time>length(HashedCells))
%         return
%     else
%         trackIDs = [HashedCells{time}(ismember([HashedCells{time}.hullID],hullIDs)).trackID];
%     end
% end