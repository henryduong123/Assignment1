function dirFlag = GetSelectedDirTo(time)
    global SelectStruct CellTracks
    
    dirFlag = 1;
    if ( isempty(SelectStruct) )
        return;
    end
    
    if ( isempty(SelectStruct.selectedTrackID) )
        return;
    end
    
    trackID = SelectStruct.selectedTrackID;
    
    dirFlag = sign(SelectStruct.selectCosts(trackID));
    if ( dirFlag == 0 )
        editTime = (time - CellTracks(trackID).startTime);
        
        dirFlag = sign(editTime);
        if ( abs(editTime) < 1 )
            dirFlag = 1;
        end
    end
end
