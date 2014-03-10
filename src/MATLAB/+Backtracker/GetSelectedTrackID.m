function trackID = GetSelectedTrackID()
    global SelectStruct
    
    trackID = 0;
    if ( isempty(SelectStruct) )
        return;
    end
    
    if ( isempty(SelectStruct.selectedTrackID) )
        return;
    end
    
    trackID = SelectStruct.selectedTrackID;
end
