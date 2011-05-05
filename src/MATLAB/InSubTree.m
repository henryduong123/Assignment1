%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     This file is part of LEVer.exe
%     (C) 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function bool = InSubTree(rootTrack,questionTrack)
% InSubTree(rootTrack,questionTrack) will return a flag which represents
% whether or not the questionTrack falls within the subtree rooted at
% rootTrack


global CellTracks
bool = 0;

%check if they are in the same family
if(CellTracks(rootTrack).familyID ~= CellTracks(questionTrack).familyID),return,end

%check if the track in question exists after the root
if(CellTracks(rootTrack).endTime > CellTracks(questionTrack).startTime),return,end

bool = traverse(rootTrack,questionTrack);
end

function bool = traverse(rootTrack,questionTrack)
%modified depth first search wich does not go passed the time of the
%questionTrack

global CellTracks

bool = 0;

if (rootTrack == questionTrack)
    bool = 1;
    return
elseif (CellTracks(rootTrack).endTime > CellTracks(questionTrack).startTime)
    return
end

for i=1:length(CellTracks(rootTrack).childrenTracks)
    bool = traverse(CellTracks(rootTrack).childrenTracks(i),questionTrack);
    %once found, return
    if(bool)
        return
    end
end
end
