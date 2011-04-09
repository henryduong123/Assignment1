function ExportImage(figureHandle)
%this function is intended to create a high resolution file of the given
%figure for printing or sharing

%--Eric Wait

global Figures

if(figureHandle == Figures.cells.handle)
elseif(figureHandle == Figures.tree.handle)
else
    %don't know what to do with this figure
    %doing nothing
end
end
