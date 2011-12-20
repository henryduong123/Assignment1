//***********************************************************************
//
//    Copyright 2011 Andrew Cohen, Eric Wait and Mark Winter
// 
//    This file is part of LEVer - the tool for stem cell lineaging. See
//    https://pantherfile.uwm.edu/cohena/www/LEVer.html for details
// 
//    LEVer is free software: you can redistribute it and/or modify
//    it under the terms of the GNU General Public License as published by
//    the Free Software Foundation, either version 3 of the License, or
//    (at your option) any later version.
// 
//    LEVer is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the//    GNU General Public License for more details.
// 
//    You should have received a copy of the GNU General Public License
//    along with LEVer in file "gnu gpl v3.txt".  If not, see 
//    <http://www.gnu.org/licenses/>.
//
//
//***********************************************************************

#include "mex.h"

#include <map>
#include <vector>
#include <limits>
#include <algorithm>

#include "CEdgeSubgraph.h"
#include "bestPaths.h"
#include "cost.h"

#ifdef MEXMAT_EXPORTS
 #define MEXMAT_LIB __declspec(dllexport)
#else
 #define MEXMAT_LIB __declspec(dllimport)
#endif

#define C_IDX(x)		(x)
#define MATLAB_IDX(x)	((x)-1)

// Globals
extern const mxArray* gCellHulls;
extern const mxArray* gCellTracks;
extern const mxArray* gHashHulls;
extern const mxArray* gCellConnDist;

extern const mxArray* gTrackHulls;

extern CEdgeSubgraph* gConnectPtr;

extern int gWindowSize;
extern int gNumFrames;
extern int gConstraintFrames;

extern const double gVMax;
extern const double gCCMax;
extern const double gAMax;