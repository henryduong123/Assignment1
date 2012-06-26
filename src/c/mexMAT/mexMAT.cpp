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

#include "mexMAT.h"

#define ARRAY_SIZE(x) (sizeof(x) / sizeof((x)[0]))


//Global variables

const mxArray* gCellHulls;
const mxArray* gCellTracks;
const mxArray* gHashHulls;
const mxArray* gConstants;
const mxArray* gCellConnDist;

const mxArray* gTrackHulls;

CEdgeSubgraph* gConnectPtr;

char* cellHullsFields[] = {"time", "points", "centerOfMass", "indexPixels", "imagePixels"};
char* cellTracksFields[] = {"familyID", "parentTrack", "siblingTrack", "childrenTracks", "hulls", "startTime", "endTime", "color"};
char* hashHullsFields[] = {"hullID", "trackID"};

int cellHullsFIdx[ARRAY_SIZE(cellHullsFields)];
int cellTracksFIdx[ARRAY_SIZE(cellTracksFields)];
int hashHullsFIdx[ARRAY_SIZE(hashHullsFields)];

int gWindowSize;
int gNumFrames;
int gConstraintFrames;

double gVMax;
double gCCMax;

const double gCostEpsilon = 1e-3;

//

void checkInputs(int nrhs, const mxArray* prhs[], int expectNumArgs, char* expectTypes[])
{
	char errMsg[100];

	if ( nrhs != expectNumArgs )
	{
		sprintf(errMsg, "Function requires %d input arguments.", expectNumArgs);
		mexErrMsgTxt(errMsg);
	}

	for ( int i=0; i < nrhs; ++i )
	{
		if ( !mxIsClass(prhs[i], expectTypes[i]) )
		{
			sprintf(errMsg, "Incorrect type for parameter %d (expected %s, got %s).", i+1, expectTypes[i], mxGetClassName(prhs[i]));
			mexErrMsgTxt(errMsg);
		}
	}
}

void buildStructFieldIdx(int fieldIdx[], int numFields, char* fieldNames[], const mxArray* structArray)
{
	char errMsg[100];

	for (  int i=0; i < numFields; ++i)
	{
		int idx = mxGetFieldNumber(structArray, fieldNames[i]);
		if ( idx < 0 )
		{
			sprintf(errMsg, "Expected field not found: %s.", fieldNames[i]);
			mexErrMsgTxt(errMsg);
		}

		fieldIdx[i] = idx;
	}
}

void mexFunction(int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[])
{
	char* expectTypes[] = {"double", "double", "cell", "struct", "cell", "struct"};
	int expectNumArgs = ARRAY_SIZE(expectTypes);

	checkInputs(nrhs, prhs, expectNumArgs, expectTypes);

	if ( nlhs != 1 )
		mexErrMsgTxt("Function must have exactly 1 output argument.");

	if ( mxGetNumberOfElements(prhs[0]) != 1 )
		mexErrMsgTxt("Parameter 1 must be a scalar frame number.");

	const mxArray* gConstants = mexGetVariablePtr("global", "CONSTANTS");
	if ( gConstants == NULL )
		mexErrMsgTxt("Global CONSTANTS variable unavailable.");

	gVMax = mxGetScalar(mxGetField(gConstants, C_IDX(0), "dMaxCenterOfMass"));
	gCCMax = mxGetScalar(mxGetField(gConstants, C_IDX(0), "dMaxConnectComponentTracker"));

	int dir = ((int) mxGetScalar(prhs[0]));
	gWindowSize = ((int) mxGetScalar(prhs[1]));

	gTrackHulls = prhs[2];
	gCellHulls = prhs[3];
	gHashHulls = prhs[4];
	gCellTracks = prhs[5];

	gCellConnDist = mexGetVariablePtr("global", "ConnectedDist");

	if ( gCellHulls == NULL || gCellTracks == NULL || gHashHulls == NULL || gCellConnDist == NULL )
		mexErrMsgTxt("Unable to access global cell variables.");

	gNumFrames = mxGetN(gHashHulls);
	int otherDim = mxGetM(gHashHulls);
	if ( gNumFrames < 2 || otherDim > 1 )
		mexErrMsgTxt("HashedCells must be a 1xN hashed cell structure.");

	otherDim = mxGetM(gTrackHulls);
	if ( gWindowSize < 2 || otherDim > 1 )
		mexErrMsgTxt("Parameter 2 must contain at least two cell rows.");

	// Build global indices for structure fields
	buildStructFieldIdx(cellHullsFIdx, ARRAY_SIZE(cellHullsFields), cellHullsFields, gCellHulls);
	buildStructFieldIdx(cellTracksFIdx, ARRAY_SIZE(cellTracksFields), cellTracksFields, gCellTracks);
	buildStructFieldIdx(hashHullsFIdx, ARRAY_SIZE(hashHullsFields), hashHullsFields, mxGetCell(gHashHulls,0));

	gConstraintFrames = mxGetNumberOfElements(gTrackHulls);
	int numTracks = mxGetNumberOfElements(mxGetCell(gTrackHulls,C_IDX(0)));
	int numNextHulls = mxGetNumberOfElements(mxGetCell(gTrackHulls,C_IDX(1)));

	if ( numTracks < 1 )
		mexErrMsgTxt("Must have nodes to track from.");
	if ( numNextHulls < 1 )
		mexErrMsgTxt("Must have nodes to track to.");

	CEdgeSubgraph connGraph(mxGetCell(gTrackHulls,C_IDX(0)), mxGetCell(gTrackHulls,C_IDX(1)));
	gConnectPtr = &(connGraph);

	buildBestPaths(dir, numTracks);

	// Set output pointer to the internal matlab pointer in EdgeSubgraph
	plhs[0] = gConnectPtr->graphPointer();
}
