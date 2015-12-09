function BuildTrackingData(objTracks, gConnect)
    global CONSTANTS Costs GraphEdits ResegLinks CellHulls CellFamilies CellTracks HashedCells CellPhenotypes

    %ensure that the globals are empty
    Costs = gConnect;
    GraphEdits = sparse([], [], [], size(Costs,1), size(Costs,2), round(0.1*size(Costs,2)));
    ResegLinks = sparse([], [], [], size(Costs,1), size(Costs,2), round(0.1*size(Costs,2)));
    
    CellFamilies = [];
    CellTracks = [];
    HashedCells = [];
    
    CellPhenotypes = struct('descriptions', {{'died'}}, 'hullPhenoSet', {zeros(2,0)});
    
    hullList = [];
    for i=length(objTracks):-1:1
        UI.Progressbar((length(objTracks)-i) / (length(objTracks)));
        
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
            UI.Progressbar(i/length(reprocess));
            Families.NewCellFamily(reprocess(i));
        end
    end
    UI.Progressbar(1);
    
    Load.InitializeCachedCosts(1);
    
    errors = mexIntegrityCheck();
    if ( ~isempty(errors) )
        Dev.PrintIntegrityErrors(errors);
    end


    %create the family trees
    Families.ProcessNewborns();
end

function hullList = addToTrack(hullID, hullList, objTracks)
    global CellHulls
    
    if ( any(ismember(hullList,hullID)) || objTracks(hullID).inID ~= 0 )
        return
    end

    Families.NewCellFamily(hullID);
    hullList = [hullList hullID];

    nextHull = hullID;
    while ( objTracks(nextHull).outID ~= 0 )
        nextHull = objTracks(nextHull).outID;
        
        if ( any(ismember(hullList,nextHull)) )
            break;
        end
        
        if ( any(ismember(hullList,objTracks(nextHull).inID)) )
            Tracks.AddHullToTrack(nextHull,[],objTracks(nextHull).inID);
        else
            %this runs if there was an error in objTracks data structure
            Families.NewCellFamily(hull);
        end
        
        hullList = [hullList nextHull];
    end
end