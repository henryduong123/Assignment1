
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     Copyright 2011-2016 Andrew Cohen
%
%     This file is part of LEVer - the tool for stem cell lineaging. See
%     http://n2t.net/ark:/87918/d9rp4t for details
% 
%     LEVer is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
%     LEVer is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
% 
%     You should have received a copy of the GNU General Public License
%     along with LEVer in file "gnu gpl v3.txt".  If not, see 
%     <http://www.gnu.org/licenses/>.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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