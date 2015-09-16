function gmmObj = fitGMM(X,k,varargin)
    if ( verLessThan('matlab', '8.4.0') )
        gmmObj = gmdistribution.fit(X,k, varargin{:});
    else
        gmmObj = fitgmdist(X,k, varargin{:});
    end
end
