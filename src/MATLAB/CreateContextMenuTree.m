function CreateContextMenuTree()
%creates the context menu for the figure that displays the tree data and
%the subsequent function calls

%--Eric Wait

global Figures

figure(Figures.tree.handle);
Figures.tree.contextMenuHandle = uicontextmenu;

uimenu(Figures.tree.contextMenuHandle,...
    'Label',        'Change Label',...
    'CallBack',     @changeLabel);

uimenu(Figures.tree.contextMenuHandle,...
    'Label',        'Change Parent',...
    'CallBack',     @changeParent);

uimenu(Figures.tree.contextMenuHandle,...
    'Label',        'Remove From Tree',...
    'CallBack',     @removeFromTree);

uimenu(Figures.tree.contextMenuHandle,...
    'Label',        'Properties',...
    'CallBack',     @properties,...
    'Separator',    'on');
end

%% Callback functions
function changeLabel(src,evnt)
global CellTracks
trackID = get(gco,'UserData');
ContextChangeLabel(CellTracks(trackID).startTime,trackID);
end

function changeParent(src,evnt)
global CellTracks
trackID = get(gco,'UserData');
ContextChangeParent(trackID,CellTracks(trackID).startTime);
end

function removeFromTree(src,evnt)
global CellTracks
trackID = get(gco,'UserData');
ContextRemoveFromTree(CellTracks(trackID).startTime,trackID);
end

function properties(src,evnt)
global CellTracks
trackID = get(gco,'UserData');
ContextProperties(CellTracks(trackID).hulls(1),trackID);
end
