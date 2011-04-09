function AddFields()

global HashedCells

if(~isfield([HashedCells{:}],'editedFlag'))
    for i=1:length(HashedCells)
        for j = 1:length(HashedCells{i})
            HashedCells{i}(j).editedFlag = 0;
        end
    end
end
end