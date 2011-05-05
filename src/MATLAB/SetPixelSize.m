%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     This file is part of LEVer.exe
%     (C) 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function SetPixelSize(axisHandle, pixSz)

    
    parentHandle = get(axisHandle, 'Parent');
    if ( ~ishandle(parentHandle) )
        return
    end
    
    oldUnits = get(axisHandle, 'Units');
    set(axisHandle, 'Units','pixels');
    
    curPos = get(axisHandle, 'Position');
    newPos = [curPos(1:2) pixSz];
    
    %figPos = get(parentHandle, 'Position');
    figPos = [1 1 (2*newPos(1:2)+newPos(3:4))];
        
    set(parentHandle, 'Position',figPos);
    set(axisHandle, 'Position',newPos);
    
    set(axisHandle, 'Units',oldUnits);
end