function BuildTrackingData(hullTracks, gConnect)
    global Costs GraphEdits ResegLinks CellHulls CellFamilies CellTracks HashedCells CellPhenotypes

    %ensure that the globals are empty
    Costs = gConnect;
    GraphEdits = sparse([], [], [], size(Costs,1), size(Costs,2), round(0.1*size(Costs,2)));
    ResegLinks = sparse([], [], [], size(Costs,1), size(Costs,2), round(0.1*size(Costs,2)));
    
    CellFamilies = [];
    CellTracks = [];
    HashedCells = [];
    
    CellPhenotypes = struct('descriptions', {{'died'}}, 'hullPhenoSet', {zeros(2,0)});
    
    hullList = [];
    for i=length(hullTracks):-1:1
        UI.Progressbar((length(hullTracks)-i) / (length(hullTracks)));
        
        if ( any(ismember(hullList,i)) )
            continue;
        end
        
        allTrackHulls = find(hullTracks == hullTracks(i));
        hullList = [hullList addToTrack(allTrackHulls)];
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

function hullList = addToTrack(allTrackHulls)  
    if ( isempty(allTrackHulls) )
        return
    end

    Families.NewCellFamily(allTrackHulls(1));
    for i=2:length(allTrackHulls)
        Tracks.AddHullToTrack(allTrackHulls(i),[],allTrackHulls(i-1));
    end
    
    hullList = allTrackHulls;
end
