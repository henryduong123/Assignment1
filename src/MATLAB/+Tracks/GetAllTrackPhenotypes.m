% GetAllTrackPhenotypes.m - Get all the phenotypes and associated hullIDs
% which have been set along a given track.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%     Copyright 2016 Drexel University
%
%     This file is part of LEVer - the tool for stem cell lineaging. See
%     http://n2t.net/ark:/87918/d9rp4t for details
% 
%     LEVer is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
%     LEVer is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
% 
%     You should have received a copy of the GNU General Public License
%     along with LEVer in file "gnu gpl v3.txt".  If not, see 
%     <http://www.gnu.org/licenses/>.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [phenotypes hullIDs] = GetAllTrackPhenotypes(trackID)
    global CellTracks
    
    hullIDs = [];
    phenotypes = [];
    
    if ( trackID < 0 || trackID > length(CellTracks) )
        return;
    end

    nzHulls = CellTracks(trackID).hulls(CellTracks(trackID).hulls > 0);
    hullPheno = getHullPhenos(nzHulls);
    
    phenotypes = hullPheno(hullPheno > 0);
    hullIDs = nzHulls(hullPheno > 0);
end

function phenos = getHullPhenos(hullIDs)
    global CellPhenotypes

    phenos = zeros(size(hullIDs));
    
    if ( isempty(CellPhenotypes.hullPhenoSet) )
        return;
    end
    
    [bMember idx] = ismember(hullIDs, CellPhenotypes.hullPhenoSet(1,:));
    phenos(bMember) = CellPhenotypes.hullPhenoSet(2,idx(bMember));
end

