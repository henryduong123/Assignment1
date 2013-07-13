function [toolboxStruct externalStruct squashNames squashGraph] = GetExternalDependencies(chkPath)
    if ( ~exist('chkPath', 'var') )
        chkPath = pwd();
    end
    
    [localNames localFileNames] = getLocalNames(chkPath);
    [fullNames calledFrom] = recursiveGetDeps(localFileNames);
    
    bIsLocal = cellfun(@(x)(~isempty(strfind(x,chkPath))), fullNames);
    localNodeList = find(bIsLocal);
    
    [toolboxes toolboxMap] = getMatlabToolboxes(fullNames);
    toolboxFuncs = arrayfun(@(x)(fullNames(toolboxMap == x)), 1:length(toolboxes), 'UniformOutput',0);
    
    bIsMatlab = (toolboxMap > 0);
    [externalDeps externalMap] = getOtherDeps(fullNames, bIsMatlab, bIsLocal);
    externalFuncs = arrayfun(@(x)(fullNames(externalMap == x)), 1:length(externalDeps), 'UniformOutput',0);
    
%     toolboxMap(externalMap > 0) = externalMap(externalMap > 0) + length(toolboxes);
%     toolboxes = [toolboxes; externalDeps];
    
    fullGraph = createCallGraph(calledFrom);
    bIsCalled = findCalledNodes(localNodeList, fullGraph);
    
    calledNames = fullNames(bIsCalled);
    callGraph = fullGraph(bIsCalled,bIsCalled);
    callToolboxMap = toolboxMap(bIsCalled);
    
    [squashNames squashGraph squashMap] = squashToolboxNodes(calledNames, callGraph, toolboxes, callToolboxMap);
    
    usedToolboxes = unique(callToolboxMap(callToolboxMap>0));
    toolboxes = toolboxes(usedToolboxes);
    
    toolboxStruct = struct('deps', {toolboxes}, 'funcs', {toolboxFuncs});
    externalStruct = struct('deps', {externalDeps}, 'funcs', {externalFuncs});
end

function [toolboxes toolboxMap] = getMatlabToolboxes(funcNames)
    bIsMatlab = cellfun(@(x)(~isempty(strfind(x,matlabroot))), funcNames);
    matlabIdx = find(bIsMatlab);
    matlabNames = funcNames(bIsMatlab);
    
    % Add default matlab dependencies first, these will always be used
    toolboxes = {'matlab';'local';'shared'};
    toolboxMap = zeros(length(funcNames),1);
    for i=1:length(matlabNames)
        toolboxPattern = '(?<=^.+[\\/]toolbox[\\/])[^\\/]+';
        matchToolbox = regexp(matlabNames{i}, toolboxPattern, 'match', 'once');
        if ( isempty(matchToolbox) )
            continue;
        end
        
        if ( any(strcmpi(matchToolbox,toolboxes)) )
            toolboxMap(matlabIdx(i)) = find(strcmpi(matchToolbox,toolboxes));
            continue;
        end
        
        toolboxes = [toolboxes; {matchToolbox}];
        toolboxMap(matlabIdx(i)) = length(toolboxes);
    end
end

function [externalDeps externalMap] = getOtherDeps(funcNames, bIsMatlab, bIsLocal)
    externalMap = zeros(length(funcNames),1);
    externalDeps = {};
    
    bExternal = (~bIsMatlab & ~bIsLocal);
    externalFuncs = funcNames(bExternal);
    
    tokenRemains = externalFuncs;
    tokenDelims = filesep;
    
    pred = [];
    bLeaves = false(0,0);
    
    pathNodes = {};
    nodeMap = ((1:length(externalFuncs)).');
    sharedPred = zeros(length(externalFuncs),1);
    
    depth = 1;
    nextPred = zeros(length(externalFuncs),1);
    bEmpty = false;
    while ( ~all(bEmpty) )
        [tokenNodes tokenRemains] = strtok(tokenRemains, tokenDelims);
        
        bEmpty = cellfun(@(x)(isempty(x)), tokenNodes);
        
        tokenNodes = tokenNodes(~bEmpty);
        tokenRemains = tokenRemains(~bEmpty);
        
        nextPred = nextPred(~bEmpty);
        nodeMap = nodeMap(~bEmpty);
        
        [newNodes ia ic] = unique(tokenNodes);
        
        bEmptyLeaf = cellfun(@(x)(isempty(x)), tokenRemains);
        bNewLeaves = bEmptyLeaf(ia);
        
        pred = [pred; nextPred(ia)];
        
        % As soon as we hit a leaf node, update shared predecessor for all
        % nodes. This will be condsidered the toolbox path.
        leafPreds = unique(nextPred(ia(bNewLeaves)));
        [bShared setPred] = ismember(nextPred, leafPreds);
        
        bUpdateShared = (sharedPred(nodeMap) == 0) & bShared;
        sharedPred(nodeMap(bUpdateShared)) = leafPreds(setPred(bUpdateShared));
        
        nextPred = ic + length(pathNodes);
        
        bLeaves = [bLeaves; bNewLeaves];
        pathNodes = [pathNodes; newNodes];
        
        depth = depth + 1;
    end
    
    [sharedPath ia ic] = unique(sharedPred);
    externalDeps = cell(length(sharedPath),1);
    for i=1:length(sharedPath)
        curIdx = sharedPath(i);
        while ( curIdx ~= 0 )
            externalDeps{i} = fullfile(pathNodes{curIdx}, externalDeps{i});
            curIdx = pred(curIdx);
        end
    end
    
    externalMap(bExternal) = ic;
end

function callGraph = createCallGraph(calledFrom)
    numEdges = cellfun(@(x)(length(x)), calledFrom);
    calledIdx = arrayfun(@(x,y)(y*ones(1,x)), numEdges, ((1:length(calledFrom)).'), 'UniformOutput',0);
    
    jIdx = ([calledIdx{:}]);
    iIdx = ([calledFrom{:}]);
    
    callGraph = sparse(iIdx,jIdx, ones(1,sum(numEdges)), length(calledFrom),length(calledFrom), sum(numEdges));
end

function bIsCalled = findCalledNodes(localFuncNames, callGraph)
    bIsCalled = false(size(callGraph,1),1);
    bIsCalled(localFuncNames) = 1;
    
    for i=1:length(localFuncNames)
        [d pred] = dijkstra_sp(callGraph, localFuncNames(i));
        
        bHasPath = ~isinf(d);
        bIsCalled = (bIsCalled | bHasPath);
    end
end

function [squashNames squashGraph squashMap] = squashToolboxNodes(funcNames, callGraph, toolboxes, toolboxMap)
    squashNames = funcNames;
    squashMap = toolboxMap;
    squashGraph = callGraph;
    
    for i=1:length(toolboxes)
        bInToolbox = (squashMap == i);
        
        tempRows = any(squashGraph(bInToolbox,:),1);
        squashRows = [tempRows(~bInToolbox) any(tempRows(bInToolbox))];
        
        tempCols = any(squashGraph(:,bInToolbox),2);
        squashCols = tempCols(~bInToolbox);
        
        squashGraph = [squashGraph(~bInToolbox,~bInToolbox) squashCols; squashRows];
        
        squashNames = [squashNames(~bInToolbox); toolboxes(i)];
        squashMap = [squashMap(~bInToolbox); i];
    end
end

function [deplist calledFrom] = recursiveGetDeps(checkNames, deplist, calledFrom)
    if ( ~exist('calledFrom','var') )
        calledFrom = {};
    end
    
    if ( ~exist('deplist','var') )
        deplist = {};
    end
    
    if ( isempty(checkNames) )
        return;
    end
    
    % Get single-link dependencies
    try
        [newdeps, builtins, classes, prob_files, prob_sym, eval_strings, newCalledFrom, java_classes] = depfun(checkNames, '-toponly', '-quiet');
    catch
        newdeps = cell(0,1);
        newCalledFrom = cell(0,1);
    end
    [deplist calledFrom newEntries] = mergeLists(deplist, calledFrom, newdeps, newCalledFrom);
    
    [deplist calledFrom] = recursiveGetDeps(newEntries, deplist, calledFrom);
    
end

function [deplist calledFrom newEntries] = mergeLists(deplist, calledFrom, newdeps, newCalledFrom)
    newIdx = cellfun(@(x)(find(strcmpi(x,deplist))), newdeps, 'UniformOutput',0);
    bNew = cellfun(@(x)(isempty(x)), newIdx);
    
    newEntries = newdeps(bNew);
    
    idxMap = zeros(1,length(newdeps));
    idxMap(~bNew) = [newIdx{~bNew}];
    idxMap(bNew) = (1:length(newEntries)) + length(deplist);
    
    deplist = [deplist; newEntries];
    calledFrom = [calledFrom; cell(length(newEntries),1)];
    
    calledFrom(idxMap) = cellfun(@(x,y)(union(x,idxMap(y))), calledFrom(idxMap), newCalledFrom, 'UniformOutput',0);
end

function [checkNames fullNames] = getLocalNames(dirName, packageString)
    if ( ~exist('packageString','var') )
        packageString = '';
    end

    matlabFiles = what(dirName);
    
    funcFileNames = vertcat(matlabFiles.m);
    funcFileNames = [funcFileNames; vertcat(matlabFiles.mex)];
    
    checkNames = cellfun(@splitFName, funcFileNames, 'UniformOutput',0);
    checkNames = cellfun(@(x)([packageString x]), checkNames, 'UniformOutput',0);
    fullNames = cellfun(@(x)(fullfile(dirName,x)), funcFileNames, 'UniformOutput',0);
    
    for i=1:length(matlabFiles.packages)
        nextPackageString = makePackageString(packageString, matlabFiles.packages{i});
        [pckgCheckNames pckgFullNames] = getLocalNames(fullfile(dirName, ['+' matlabFiles.packages{i}]), nextPackageString);
        
        checkNames = [checkNames; pckgCheckNames];
        fullNames = [fullNames; pckgFullNames];
    end
end

function packageString = makePackageString(packageString, nextPackage)
    if ( isempty(packageString) )
        packageString = [nextPackage '.'];
        return;
    end
    
    packageString = [packageString nextPackage '.'];
end

function name = splitFName(fileName)
    [path, name] = fileparts(fileName);
end
