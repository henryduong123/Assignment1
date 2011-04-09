function gConnect = trackingCosts(trackHulls, t, avoidHulls, hulls, hash)
    windowSize = 4;
    gConnect = sparse([],[],[],length(hulls),length(hulls),round(0.1*length(hulls)));
    
    if ( t+1 > length(hash) )
        return;
    end
    
    apc = cell(length(trackHulls),1);
    
    for i=1:length(trackHulls)
        % Build constraints from avoidance lists
        constraints = cell(windowSize,1);
        for j=1:min(windowSize, (length(hash)-t))
            constraints{j} = setdiff([hash{t+j}.hullID], avoidHulls);
        end
        
        [gConnect, apc{i}] = constrainedBestPath(trackHulls(i), t, t+windowSize, constraints, hulls, hash, gConnect);
    end
end