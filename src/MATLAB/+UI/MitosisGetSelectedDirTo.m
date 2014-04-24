function dirFlag = MitosisGetSelectedDirTo(time)
    global MitosisEditStruct CellTracks
    
    dirFlag = 1;
    if ( isempty(MitosisEditStruct) )
        return;
    end
    
    if ( isempty(MitosisEditStruct.selectedTrackID) )
        return;
    end
    
    trackID = MitosisEditStruct.selectedTrackID;
    
    dirFlag = sign(MitosisEditStruct.selectCosts(trackID));
    if ( dirFlag == 0 )
        editTime = (time - CellTracks(trackID).startTime);
        
        dirFlag = sign(editTime);
        if ( abs(editTime) < 1 )
            dirFlag = 1;
        end
    end
end
