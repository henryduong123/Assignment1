function pixSz = GetPixelSize(axisHandle)

%--Mark Winter

    oldUnits = get(axisHandle, 'Units');
    set(axisHandle, 'Units','pixels');
    
    pos = get(axisHandle, 'Position');
    set(axisHandle, 'Units',oldUnits);
    
    pixSz = pos(3:4);
end