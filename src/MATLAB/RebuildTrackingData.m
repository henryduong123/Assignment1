function RebuildTrackingData(objTracks, gConnect)
    global CONSTANTS Costs GraphEdits CellHulls CellFamilies CellTracks HashedCells

    %ensure that the globals are empty
    Costs = gConnect;
    GraphEdits = sparse([], [], [], size(Costs,1), size(Costs,2), round(0.1*size(Costs,2)));
    
    CellFamilies = [];
    CellTracks = [];
    HashedCells = [];
    
    hullList = [];
    for i=length(objTracks):-1:1
        Progressbar((length(objTracks)-i) / (length(objTracks)));
        
        if ( any(ismember(hullList,i)) )
            continue;
        end
        
        if ( objTracks(i).inID ~= 0 )
            continue;
        end
        
        hullList = addToTrack(i,hullList,objTracks);
    end
    
    if ( length(hullList) ~= length(CellHulls) )
        reprocess = setdiff(1:length(CellHulls), hullList);
        for i=1:length(reprocess)
            Progressbar(i/length(reprocess));
            NewCellFamily(reprocess(i), CellHulls(reprocess(i)).time);
        end
    end
    Progressbar(1);
    
    try
        TestDataIntegrity(1);
    catch errormsg
        fprintf('\n%s\n',errormsg.message);
        ProgressBar(1);
    end

    %create the family trees
    ProcessNewborns(1:length(CellFamilies), length(HashedCells));
end

function hullList = addToTrack(hullID, hullList, objTracks)
    global CellHulls
    
    if ( any(ismember(hullList,hullID)) || objTracks(hullID).inID ~= 0 )
        return
    end

    NewCellFamily(hullID, CellHulls(hullID).time);
    hullList = [hullList hullID];

    nextHull = hullID;
    while ( objTracks(nextHull).outID ~= 0 )
        nextHull = objTracks(nextHull).outID;
        
        if ( any(ismember(hullList,nextHull)) )
            break;
        end
        
        if ( any(ismember(hullList,objTracks(nextHull).inID)) )
            AddHullToTrack(nextHull,[],objTracks(nextHull).inID);
        else
            %this runs if there was an error in objTracks data structure
            NewCellFamily(hull,objTracks(hull).t);
        end
        
        hullList = [hullList nextHull];
    end
end