%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     This file is part of LEVer.exe
%     (C) 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function pixSz = GetPixelSize(axisHandle)


    oldUnits = get(axisHandle, 'Units');
    set(axisHandle, 'Units','pixels');
    
    pos = get(axisHandle, 'Position');
    set(axisHandle, 'Units',oldUnits);
    
    pixSz = pos(3:4);
end