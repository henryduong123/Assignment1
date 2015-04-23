function gmmObj = fitGMM(X,k,varargin)
    if ( verLess('8.4.0') )
        gmmObj = gmdistribution.fit(X,k, varargin{:});
    else
        gmmObj = fitgmdist(X,k, varargin{:});
    end
end

function bLess = verLess(versionStr)
    persistent matVer
    
    bLess = false;
    if ( isempty(matVer) )
        v = version();
        matchTok = regexp(v,'(\d+\.\d+\.\d+)\..+', 'tokens','once');
        matVer = matchTok{1};
    end
    
    if ( strcmp(matVer,versionStr) )
        return;
    end
    
    bLess = issorted({versionStr; matVer}, 'rows');
end