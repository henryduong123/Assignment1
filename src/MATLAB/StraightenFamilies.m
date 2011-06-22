function StraightenFamilies()
    global CellFamilies
    
    i = 1;
    while ( i < length(CellFamilies) )
        if ( isempty(CellFamilies(i).startTime) )
            i = i + 1;
            continue;
        end
        
        StraightenTrack(CellFamilies(i).rootTrackID);
        
        i = i + 1;
    end
end