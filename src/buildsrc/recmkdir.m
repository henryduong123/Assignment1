
function recmkdir(dirname)
	[pathelems, driveletter] = splitpath(dirname);
    
    drv = [];
    if ( ~isempty(driveletter) )
        drv = [driveletter ':'];
    end
    
    pathcheck = drv;
    for i=1:length(pathelems)
        pathcheck = fullfile(pathcheck,pathelems{i},'');
        if ( ~exist(pathcheck, 'dir') )
            mkdir(pathcheck);
            %disp(['making: ' pathcheck]);
        end
    end
end

function [pathelems, drive] = splitpath(path)
    % Strip leading and ending quotes if necessary
    if ( path(1) == '"' )
        path = path(2:end-1);
    end
    
    drive = [];
    pathelems = [];
    
    [parseelem, residual] = strtok(path, filesep);
    if ( parseelem(end) == ':' )
        drive = parseelem(1:end-1);
    else
        pathelems{end+1} = parseelem;
    end
    
    while ( ~isempty(residual) )
        [parseelem, residual] = strtok(residual, filesep);
        if ( ~isempty(parseelem) )
            pathelems{end+1} = parseelem;
        end
    end
end