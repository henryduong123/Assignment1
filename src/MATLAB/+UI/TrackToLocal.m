% Returns the local (short) label for a track
function localTrackStr = TrackToLocal(localLabels, trackID)
    global Figures
    
    bUseShortLabels = strcmp('on',get(Figures.tree.menuHandles.shortLabelsMenu, 'Checked'));

    if bUseShortLabels && isKey(localLabels, trackID)
        localTrackStr = localLabels(trackID);
    else
        % There's no short label for this trackID, so just return the actual trackID.
        localTrackStr = num2str(trackID);
    end
end