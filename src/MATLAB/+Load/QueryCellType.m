function cellType = QueryCellType()
    SupportedTypes = Load.GetSupportedCellTypes();
    
%     [cellType Ok] = listdlg('ListString',SupportedTypes, 'SelectionMode','single', 'Name','Select Cell Type', 'ListSize',[200 100]);

    typeNames = {SupportedTypes.name};

    hDialog = dialog('Name','Select Cell Type', 'Visible','off', 'CloseRequestFcn','');
    
    dlgpos = get(hDialog, 'Position');
    set(hDialog, 'Position',[dlgpos(1:2) 230 40]);
    
    hComboBox = uicontrol(hDialog, 'Style','popupmenu', 'String',typeNames, 'Position',[20 12 100 20]);
    hButton = uicontrol(hDialog, 'Style','pushbutton', 'String','OK', 'Position',[150 10 65 22], 'Callback',@selectedCellType);
    
    set(hDialog, 'Visible','on');
    
    uicontrol(hComboBox);
    
    uiwait(hDialog);
    
    function selectedCellType(src, evnt)
        selectedIdx = get(hComboBox, 'Value');
        cellType = typeNames{selectedIdx};
        delete(hDialog);
    end
end