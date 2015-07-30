function cellHullsTemplate = GetCellHullTemplate()
    cellHullsTemplate = struct('time',{0},...
                               'points',{[]},...
                               'centerOfMass',{[0 0]},...
                               'indexPixels',{[]},...
                               'deleted',{false},...
                               'userEdited',{false},...
                               'tag',{''});
	
end