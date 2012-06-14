% PrintIntegrityErrors(errs, filename)
% Prints integrity errors to filename (or stdout if no name specified)

function PrintIntegrityErrors(errs, filename)

    if ( isempty(errs) )
        return;
    end

    if ( ~exist('filename', 'var') )
        fid = 1;
    else
        fid = fopen(filename, 'w');
    end
    
    for i=1:length(errs)
        fprintf(fid, '%s(%d) - %s\n', errs(i).type, errs(i).index, errs(i).message);
    end
    
end