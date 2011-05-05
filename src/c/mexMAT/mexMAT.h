//******************************************************
//
//    This file is part of LEVer.exe
//    (C) 2011 Andrew Cohen, Eric Wait and Mark Winter
//
//******************************************************

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

extern const double gVMax;
extern const double gCCMax;
extern const double gAMax;