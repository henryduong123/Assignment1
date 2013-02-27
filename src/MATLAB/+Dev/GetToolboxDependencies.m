function toolboxes = GetToolboxDependencies()
    curDir = pwd();
    
    [localNames localFileNames] = getLocalNames(curDir, '');
    
    [list, builtins, classes, prob_files, prob_sym, eval_strings, called_from, java_classes] = depfun(localFileNames, '-toponly', '-quiet');
    
    toolboxes = {};
    for i=1:length(list)
        toolboxPattern = '(?<=^.+[\\/]toolbox[\\/])[^\\/]+';
        matchToolbox = regexp(list{i}, toolboxPattern, 'match', 'once');
        if ( isempty(matchToolbox) )
            continue;
        end
        
        if ( any(strcmpi(matchToolbox,toolboxes)) )
            continue;
        end
        
        toolboxes = [toolboxes; {matchToolbox}];
    end
end

function [checkNames fullNames] = getLocalNames(dirName, packageString)
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