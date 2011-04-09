function ContextProperties(hullID,trackID)
%context menu callback function

global CellTracks Figures

%collect all the data that will be passed to the properties UI
vars.hullID = hullID;
vars.trackID = trackID;
vars.familyID = CellTracks(vars.trackID).familyID;
vars.startTime = CellTracks(vars.trackID).startTime;
vars.endTime = CellTracks(vars.trackID).endTime;
vars.parentTrack = CellTracks(vars.trackID).parentTrack;
vars.siblingTrack = CellTracks(vars.trackID).siblingTrack;
vars.childrenTracks = CellTracks(vars.trackID).childrenTracks;
vars.timeOfDeath = CellTracks(vars.trackID).timeOfDeath;
vars.time = Figures.time;

Properties(vars);
end
