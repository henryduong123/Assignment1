function printCostMatrix(costMatrix, fromHulls, toHulls)
    
    fprintf(1,'           |');
    fprintf(1,'  %8d',toHulls);
    fprintf(1,'\n');
    for i=1:length(toHulls)+1;
        fprintf(1,'-----------');
    end
    fprintf(1,'\n');
    for i=1:size(costMatrix,1)
        fprintf(1,'  %8d |',fromHulls(i));
        fprintf(1,'  %8.2g',costMatrix(i,:));
        fprintf(1,'\n');
    end
    fprintf(1,'\n');
end