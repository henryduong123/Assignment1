%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     This file is part of LEVer.exe
%     (C) 2011 Andrew Cohen, Eric Wait and Mark Winter
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [path allPaths] = constrainedDFS(hullIdx, constraints, hulls, hash, t0, t1, path, allPaths)
    global CONSTANTS

    curCnsts = [];
    bFoundPath = 0;
    if ( t0 < t1 && t0 < length(hash)-1 )
        path = [path hullIdx];
        
        curCnsts = constraints{length(path)};
        for i=1:length(curCnsts)
            if 105==t0
                dmax_cc=3*CONSTANTS.dMaxConnectComponet;
                dmax_com=3*CONSTANTS.dMaxCenterOfMass;
            else
                dmax_cc=CONSTANTS.dMaxConnectComponet;
                dmax_com=CONSTANTS.dMaxCenterOfMass;          
            end
            [d dSz] = HullDist(hulls, hullIdx, curCnsts(i), dmax_cc, dmax_com);

            if ~isinf(d) %& dSz<0.75
                [path allPaths]=constrainedDFS(curCnsts(i), constraints, hulls, hulls, t0+1, t1, path, allPaths);
                bFoundPath=1;
            end
        end
        
        path(end) = [];
    end
    
    if ( isempty(curCnsts) || ~bFoundPath )
        allPaths{end+1} = [path hullIdx];
    end
end