//******************************************************
//
//    This file is part of LEVer.exe
//    (C) 2011 Andrew Cohen, Eric Wait and Mark Winter
//
//******************************************************

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
char* cellTracksFields[] = {"familyID", "parentTrack", "siblingTrack", "childrenTracks", "hulls", "startTime", "endTime", "timeOfDeath", "color"};
char* hashHullsFields[] = {"hullID", "trackID"};

int cellHullsFIdx[ARRAY_SIZE(cellHullsFields)];
int cellTracksFIdx[ARRAY_SIZE(cellTracksFields)];
int hashHullsFIdx[ARRAY_SIZE(hashHullsFields)];

int gWindowSize;
int gNumFrames;

const double gVMax = 80.0;
const double gCCMax = 40.0;
//const double gAMax;

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
	char* expectTypes[] = {"double", "double", "cell", "struct", "cell"};
	int expectNumArgs = ARRAY_SIZE(expectTypes);

	checkInputs(nrhs, prhs, expectNumArgs, expectTypes);

	if ( nlhs != 1 )
		mexErrMsgTxt("Function must have exactly 1 output argument.");

	if ( mxGetNumberOfElements(prhs[0]) != 1 )
		mexErrMsgTxt("Parameter 1 must be a scalar frame number.");

	//const mxArray* gConstants = mexGetVariablePtr("global", "CONSTANTS");
	//if ( gConstants == NULL )
	//	mexErrMsgTxt("Global CONSTANTS variable unavailable.");

	int t = ((int)mxGetScalar(prhs[0]));
	gWindowSize = ((int) mxGetScalar(prhs[1]));

	gTrackHulls = prhs[2];
	gCellHulls = prhs[3];
	gHashHulls = prhs[4];

	gCellTracks = mexGetVariablePtr("global", "CellTracks");
	gCellConnDist = mexGetVariablePtr("global", "ConnectedDist");

	if ( gCellHulls == NULL || gCellTracks == NULL || gHashHulls == NULL || gCellConnDist == NULL )
		mexErrMsgTxt("Unable to access global cell variables.");

	gNumFrames = mxGetN(gHashHulls);
	int otherDim = mxGetM(gHashHulls);
	if ( gNumFrames < 2 || otherDim > 1 )
		mexErrMsgTxt("HashedCells must be a 1xN hashed cell structure.");

	if ( t < 0 || t > gNumFrames-1 )
		mexErrMsgTxt("Parameter 1 must be a valid frame number.");

	//gWindowSize = mxGetN(gTrackHulls);
	otherDim = mxGetM(gTrackHulls);
	if ( gWindowSize < 2 || otherDim > 1 )
		mexErrMsgTxt("Parameter 2 must contain at least two cell rows.");

	// Build global indices for structure fields
	buildStructFieldIdx(cellHullsFIdx, ARRAY_SIZE(cellHullsFields), cellHullsFields, gCellHulls);
	buildStructFieldIdx(cellTracksFIdx, ARRAY_SIZE(cellTracksFields), cellTracksFields, gCellTracks);
	buildStructFieldIdx(hashHullsFIdx, ARRAY_SIZE(hashHullsFields), hashHullsFields, mxGetCell(gHashHulls,0));

	int numTracks = mxGetNumberOfElements(mxGetCell(gTrackHulls,C_IDX(0)));
	int numNextHulls = mxGetNumberOfElements(mxGetCell(gTrackHulls,C_IDX(1)));

	if ( numTracks < 1 )
		mexErrMsgTxt("Must have nodes to track from.");
	if ( numNextHulls < 1 )
		mexErrMsgTxt("Must have nodes to track to.");

	CEdgeSubgraph connGraph(mxGetCell(gTrackHulls,C_IDX(0)), mxGetCell(gTrackHulls,C_IDX(1)));
	gConnectPtr = &(connGraph);

	buildBestPaths(t, numTracks);

	// Set output pointer to the internal matlab pointer in EdgeSubgraph
	plhs[0] = gConnectPtr->graphPointer();
}