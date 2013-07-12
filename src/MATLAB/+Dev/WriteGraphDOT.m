function WriteGraphDOT(callGraph, fullFuncList)
    fullNames = cellfun(@(x)(strrep(x, '\', '\\')), fullFuncList, 'UniformOutput',0);

%     toolboxes = {};
%     toolboxMap = zeros(1,length(fullFuncList));
%     for i=1:length(fullFuncList)
%         toolboxPattern = '(?<=^.+[\\/]toolbox[\\/])[^\\/]+';
%         matchToolbox = regexp(fullFuncList{i}, toolboxPattern, 'match', 'once');
%         if ( isempty(matchToolbox) )
%             continue;
%         end
%         
%         if ( any(strcmpi(matchToolbox,toolboxes)) )
%             toolboxMap(i) = find(strcmpi(matchToolbox,toolboxes));
%             continue;
%         end
%         
%         toolboxMap(i) = length(toolboxes) + 1;
%         toolboxes = [toolboxes; {matchToolbox}];
%     end
    
    % Write a DOT file representing call graph
    fid = fopen('adjmat.dot','w');
    % fprintf(fid,'digraph G {\ncenter = 1;\nsize="10,10";\n');
    fprintf(fid, 'digraph G \n{\n');
    fprintf(fid, 'rankdir=LR\n');
    fprintf(fid, 'node [shape=box]\n');
    
    bUsedNodes = false(1,length(fullFuncList));
%     for i=1:length(toolboxes)
%         bInToolbox = (toolboxMap == i);
%         tbGraph = callGraph(bInToolbox,bInToolbox);
%         subNodes = find(bInToolbox);
%         
%         fprintf(fid, 'subgraph ["%s"]\n{\n', toolboxes{i});
%         
%         for j=1:length(subNodes)
%             [funcPath shortName] = fileparts(fullFuncList{subNodes(j)});
%             fprintf(fid, '%d[label="%s"]; ', subNodes(j), shortName);
%         end
%         
%         fprintf(fid, '\n');
%         
%         [r c] = find(tbGraph);
%         for j=1:length(r)
%             fprintf(fid, '%d -> %d; ', subNodes(r(j)), subNodes(c(j)));
%         end
%         
%         fprintf(fid, '\n}\n');
%         
%         bUsedNodes(bInToolbox) = 1;
%         callGraph(bInToolbox,bInToolbox) = 0;
%     end
    
    remainingNodes = find(~bUsedNodes);
    for i=1:length(remainingNodes)
        [funcPath shortName] = fileparts(fullFuncList{remainingNodes(i)});
        fprintf(fid, '%d[label="%s"]; ', remainingNodes(i), shortName);
    end
    
    fprintf(fid, '\n');
    [r c] = find(callGraph);
    for i=1:length(r)
        fprintf(fid, '%d -> %d; ', r(i), c(i));
    end
    
    fprintf(fid, '\n}');
    fclose(fid);
end