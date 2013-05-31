% PrintIntegrityErrors(errs, filename)
% Prints integrity errors to filename (or stdout if no name specified)

function PrintIntegrityErrors(errs, fid)

    if ( isempty(errs) )
        return;
    end

    if ( ~exist('fid', 'var') )
        fid = 1;
    end
    
    for i=1:length(errs)
        fprintf(fid, '%s(%d) - %s\n', errs(i).type, errs(i).index, errs(i).message);
    end
    
end