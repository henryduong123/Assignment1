function trackID = LocalToTrack(revLocalLabels, label)
    global Figures

    bUseShortLabels = strcmp('on',get(Figures.tree.menuHandles.shortLabelsMenu, 'Checked'));

    if bUseShortLabels && isKey(revLocalLabels, label)
        trackID = revLocalLabels(label);
    else
        % This doesn't seem to be a short label, so just return whatever was passed in.
        trackID = str2double(label);
    end
end