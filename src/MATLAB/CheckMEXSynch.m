function CheckMEXSynch(checkGraph)
    [checkOut checkIn] = mexDijkstra('debugAllEdges');
    
    checkOut = sortrows(checkOut);
    checkIn = sortrows(checkIn);
    
    if ( any(checkOut(:) ~= checkIn(:)) )
        error('In/Out MEX Edges are out of synch.');
    end
    
    if ( exist('checkGraph','var') )
        [rcm, ccm] = find(checkGraph > 0);
        graphInd = sub2ind(size(checkGraph), rcm, ccm);
        checkMAT = [rcm ccm full(checkGraph(graphInd))];
        
        checkMAT = sortrows(checkMAT);
        
        if ( any(checkOut(:) ~= checkMAT(:)) )
            error('MEX Edges out of synch with Matlab.');
        end
    end
end