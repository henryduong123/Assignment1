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

#include "mexDijkstra.h"
#include "CSparseWrapper.h"

#include <vector>
#include <map>
#include <list>

#include <string.h>

#define ARRAY_SIZE(x) (sizeof(x) / sizeof((x)[0]))

// Couple of convenience macros for command handling
//#define DEFINE_COMMAND(cmdname) void mexCmd##cmdname(int nrhs, mxArray* prhs, int nlhs, const mxArray* plhs)
#define IS_COMMAND(value,cmdname) (strcmpi((value),(#cmdname)) == 0)
#define CALL_COMMAND(cmdname) {mexCmd_##cmdname(nlhs, plhs, nrhs, prhs);}

// Globals
CSparseWrapper* gCostGraph = NULL;

std::vector<double> gPathCosts;
std::vector<int> gPathLengths;
std::vector<mwIndex> gPathBack;

std::vector<bool> gbTraversed;

std::vector<mwIndex> gAcceptedPaths;

// Matlab Globals
const mxArray* gCellHulls;
const mxArray* gCellTracks;
const mxArray* gCellFamilies;
const mxArray* gHashHulls;

// Helpers
//typedef std::pair<mwIndex,mwIndex> tPriorityEdge;
typedef std::pair<double,mwIndex> tPriorityType;
typedef std::multimap<double,mwIndex> tPriorityQueue;

int getTrackID(mwIndex hullID)
{
	int time = ((int) mxGetScalar(mxGetField(gCellHulls, MATLAB_IDX(hullID), "time")));

	mxArray* frmHulls = mxGetCell(gHashHulls,MATLAB_IDX(time));
	int numFrmHulls = mxGetNumberOfElements(frmHulls);

	for ( int i=0; i < numFrmHulls; ++i )
	{
		mwIndex frmHullID = ((mwIndex) mxGetScalar(mxGetField(frmHulls, C_IDX(i), "hullID")));
		if ( frmHullID == hullID )
			return ((int) mxGetScalar(mxGetField(frmHulls, C_IDX(i), "trackID")));
	}

	return -1;
}

int findEndHull(mwIndex trackID)
{
	mxArray* trackHullArray = mxGetField(gCellTracks, MATLAB_IDX(trackID), "hulls");

	int hullsLength = mxGetNumberOfElements(trackHullArray);
	double* hulls = ((double*) mxGetData(trackHullArray));

	for ( int i=(hullsLength-1); i >= 0; --i )
	{
		if ( hulls[C_IDX(i)] > 0.0 )
			return ((int) hulls[C_IDX(i)]);
	}

	return 0;
}

bool callMatlabAcceptFunc(const mxArray* matFuncHandle, mwIndex startVert, mwIndex endVert)
{
	int nlhs = 1;
	int nrhs = 3;

	mxArray* plhs[1] = {NULL};
	mxArray* prhs[3] = {NULL, NULL, NULL};

	prhs[0] = ((mxArray*) matFuncHandle);
	prhs[1] = mxCreateNumericMatrix(1,1,mxDOUBLE_CLASS, mxREAL);
	prhs[2] = mxCreateNumericMatrix(1,1,mxDOUBLE_CLASS, mxREAL);

	((double*)mxGetData(prhs[1]))[0] = startVert;
	((double*)mxGetData(prhs[2]))[0] = endVert;

	mexCallMATLAB(nlhs, plhs, nrhs, prhs, "feval");

	int fnResult = ((int) mxGetScalar(plhs[0]));
	if ( fnResult == 0 )
		return false;

	return true;
}

bool checkAcceptPath(mwIndex startVert, mwIndex endVert, mwSize maxExtent, const mxArray* matFuncHandle)
{
	if ( !matFuncHandle )
	{
		int hullTime = ((int) mxGetScalar(mxGetField(gCellHulls, MATLAB_IDX(endVert), "time")));
		int startVertTime = ((int) mxGetScalar(mxGetField(gCellHulls, MATLAB_IDX(startVert), "time")));
		if ( (hullTime - startVertTime) < 1 )
			return false;

		int trackID = getTrackID(endVert);
		if ( trackID < 1 )
			return false;

		int startTime = ((int) mxGetScalar(mxGetField(gCellTracks, MATLAB_IDX(trackID), "startTime")));
		if ( hullTime != startTime )
			return false;

		// Valid if track has no parent
		mxArray* parentTrack = mxGetField(gCellTracks, MATLAB_IDX(trackID), "parentTrack");
		if ( mxGetNumberOfElements(parentTrack) < 1 )
			return true;


		int parentTrackID = ((int) mxGetScalar(parentTrack));
		double* childrenTracks = ((double*) mxGetData(mxGetField(gCellTracks, MATLAB_IDX(parentTrackID), "childrenTracks")));
		int childTrackID = ((int) childrenTracks[0]);
		if ( childTrackID == trackID )
			childTrackID = ((int) childrenTracks[1]);

		int childHullID = ((int) mxGetScalar(mxGetField(gCellTracks, MATLAB_IDX(childTrackID), "hulls")));
		int parentHullID = findEndHull(parentTrackID);

		// Valid if not primary tree-edge
		if ( gCostGraph->findEdge(parentHullID, childHullID) < gCostGraph->findEdge(parentHullID, endVert) )
			return true;

		return false;
	}
	else
		return callMatlabAcceptFunc(matFuncHandle, startVert, endVert);

	return false;
}

int popNextVert(tPriorityQueue& costQueue, mwSize maxExtent)
{
	tPriorityQueue::iterator nextVertIter = costQueue.begin();

	while ( nextVertIter != costQueue.end() )
	{
		mwIndex nextVert = nextVertIter->second;

		costQueue.erase(nextVertIter);
		nextVertIter = costQueue.begin();

		if ( gPathLengths[MATLAB_IDX(nextVert)] > maxExtent )
			continue;

		return nextVert;
	}

	return -1;
}

void updateVertCost(tPriorityQueue& costQueue, mwIndex vert, double newCost)
{
	double oldCost = gPathCosts[MATLAB_IDX(vert)];
	
	//if ( costQueue.count(oldCost) < 1 )
	//{
	//	costQueue.insert(tPriorityType(newCost,vert));
	//	gPathCosts[MATLAB_IDX(vert)] = newCost;
	//	return;
	//}

	tPriorityQueue::iterator updateIter;
	std::pair<tPriorityQueue::iterator,tPriorityQueue::iterator> costRange = costQueue.equal_range(oldCost);

	for ( updateIter = costRange.first; updateIter != costRange.second; ++updateIter )
	{
		if ( updateIter->second == vert )
		{
			costQueue.erase(updateIter);
			break;
		}
	}

	costQueue.insert(tPriorityType(newCost,vert));
	gPathCosts[MATLAB_IDX(vert)] = newCost;
}

void setVertPath(mwIndex curVert, mwIndex nextVert)
{
	gPathLengths[MATLAB_IDX(nextVert)] = gPathLengths[MATLAB_IDX(curVert)] + 1;
	gPathBack[MATLAB_IDX(nextVert)] = curVert;
}

void buildOutputPaths(mxArray* cellPaths, mxArray* arrayCost)
{
	double* pathCostData = ((double*) mxGetData(arrayCost));
	for ( int i=0; i < gAcceptedPaths.size(); ++i )
	{
		mwIndex termVert = gAcceptedPaths[i];

		pathCostData[C_IDX(i)] = gPathCosts[MATLAB_IDX(termVert)];

		int pathLength = gPathLengths[MATLAB_IDX(termVert)];

		mxArray* cellData = mxCreateNumericMatrix(1, pathLength, mxDOUBLE_CLASS, mxREAL);
		mxSetCell(cellPaths, C_IDX(i), cellData);

		double* pathData = ((double*) mxGetData(cellData));

		mwIndex nextVert = termVert;
		pathData[pathLength-1] = nextVert;
		for ( int j=(pathLength-2); j >=0; --j )
		{
			nextVert = gPathBack[MATLAB_IDX(nextVert)];
			pathData[C_IDX(j)] = nextVert;
		}
	}
}

// Functions
int dijkstraSearch(int startVert, mwSize maxExtent, mwSize numVerts, const mxArray* matFuncHandle)
{
	gAcceptedPaths.clear();
	for ( mwSize i=0; i < numVerts; ++i )
	{
		gPathLengths[i] = 0;
		gPathBack[i] = 0;
		gPathCosts[i] = std::numeric_limits<double>::infinity();
		gbTraversed[i] = false;
	}

	gPathLengths[MATLAB_IDX(startVert)] = 1;
	gPathCosts[MATLAB_IDX(startVert)] = 0.0;

	tPriorityQueue costQueue;

	int curVert = startVert;
	while ( curVert > 0 )
	{
		if ( checkAcceptPath(startVert, curVert, maxExtent, matFuncHandle) )
		{
			gAcceptedPaths.push_back(curVert);
			curVert = popNextVert(costQueue, maxExtent);
			continue;
		}

		double curCost = gPathCosts[MATLAB_IDX(curVert)];

		int numOutEdges = gCostGraph->getOutEdgeLength(curVert);
		CSparseWrapper::tEdgeIterator edgeIter = gCostGraph->getOutEdgeIter(curVert);
		for (int i=0; i < numOutEdges; ++edgeIter, ++i)
		{
			mwIndex nextVert = (edgeIter->first);
			if ( gbTraversed[MATLAB_IDX(nextVert)] )
				continue;

			// Don't let paths that are "too long" steal a shorter higher-cost path
			if ( (gPathLengths[MATLAB_IDX(curVert)] + 1) > maxExtent )
				continue;

			double newCost = curCost + (edgeIter->second);
			if ( gPathCosts[MATLAB_IDX(nextVert)] > newCost )
			{
				updateVertCost(costQueue, nextVert, newCost);
				setVertPath(curVert, nextVert);
			}
		}

		gbTraversed[MATLAB_IDX(curVert)] = true;

		curVert = popNextVert(costQueue, maxExtent);
	}

	return gAcceptedPaths.size();
}


void mexCmd_initGraph(int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[])
{
	if ( nlhs > 0 )
		mexErrMsgTxt("initGraph: Output values unsupported.");

	if ( nrhs < 2 || !mxIsClass(prhs[1], "double") || !mxIsSparse(prhs[1]) )
		mexErrMsgTxt("initGraph: Expected sparse matrix graph as second parameter.");

	if ( gCostGraph )
	{
		delete gCostGraph;
		gCostGraph = NULL;

		gbTraversed.clear();
		gPathCosts.clear();
		gPathLengths.clear();
		gPathBack.clear();
	}

	gCostGraph = new CSparseWrapper(prhs[1]);

	gbTraversed.resize(gCostGraph->getNumVerts());
	gPathCosts.resize(gCostGraph->getNumVerts());
	gPathLengths.resize(gCostGraph->getNumVerts());
	gPathBack.resize(gCostGraph->getNumVerts());
}

void mexCmd_checkExtension(int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[])
{
	if ( nlhs != 2 )
		mexErrMsgTxt("checkExtension: Expect 2 outputs [paths costs] from dijkstra extensions search.");

	if ( !gCostGraph )
		mexErrMsgTxt("checkExtension: Cost graph must first be initialized. Run \"initGraph\" command.");

	if ( nrhs < 2 || !mxIsClass(prhs[1], "double") || mxGetNumberOfElements(prhs[1]) != 1 )
		mexErrMsgTxt("checkExtension: Expected scalar vertex index as second parameter.");

	if ( nrhs < 3 || !mxIsClass(prhs[2], "double") || mxGetNumberOfElements(prhs[2]) != 1 )
		mexErrMsgTxt("checkExtension: Expected scalar max extent as third parameter.");

	//
	gCellHulls = mexGetVariablePtr("global", "CellHulls");
	gCellTracks = mexGetVariablePtr("global", "CellTracks");
	gCellFamilies = mexGetVariablePtr("global", "CellFamilies");
	gHashHulls = mexGetVariablePtr("global", "HashedCells");

	//
	mwIndex startVert = ((mwIndex) mxGetScalar(prhs[1]));
	mwSize maxExt = ((mwSize) mxGetScalar(prhs[2]));

	//
	int numPaths = dijkstraSearch(startVert, maxExt, gCostGraph->getNumVerts(), NULL);

	plhs[0] = mxCreateCellMatrix(1, numPaths);
	plhs[1] = mxCreateNumericMatrix(1, numPaths, mxDOUBLE_CLASS, mxREAL);

	if ( numPaths > 0 )
		buildOutputPaths(plhs[0], plhs[1]);
}

void mexCmd_matlabExtend(int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[])
{
	if ( nlhs != 2 )
		mexErrMsgTxt("matlabExtend: Expect 2 outputs [paths costs] from dijkstra extensions search.");

	if ( !gCostGraph )
		mexErrMsgTxt("matlabExtend: Cost graph must first be initialized. Run \"initGraph\" command.");

	if ( nrhs < 2 || !mxIsClass(prhs[1], "double") || mxGetNumberOfElements(prhs[1]) != 1 )
		mexErrMsgTxt("matlabExtend: Expected scalar vertex index as second parameter.");

	if ( nrhs < 3 || !mxIsClass(prhs[2], "double") || mxGetNumberOfElements(prhs[2]) != 1 )
		mexErrMsgTxt("matlabExtend: Expected scalar max extent as third parameter.");

	if ( nrhs < 4 || !mxIsClass(prhs[3], "function_handle") )
		mexErrMsgTxt("matlabExtend: Expected function handle as fourth parameter.");

	//
	gCellHulls = mexGetVariablePtr("global", "CellHulls");
	gCellTracks = mexGetVariablePtr("global", "CellTracks");
	gCellFamilies = mexGetVariablePtr("global", "CellFamilies");
	gHashHulls = mexGetVariablePtr("global", "HashedCells");

	//
	mwIndex startVert = ((mwIndex) mxGetScalar(prhs[1]));
	mwSize maxExt = ((mwSize) mxGetScalar(prhs[2]));

	const mxArray* acceptFuncHandle = prhs[3];

	//
	int numPaths = dijkstraSearch(startVert, maxExt, gCostGraph->getNumVerts(), acceptFuncHandle);

	plhs[0] = mxCreateCellMatrix(1, numPaths);
	plhs[1] = mxCreateNumericMatrix(1, numPaths, mxDOUBLE_CLASS, mxREAL);

	if ( numPaths > 0 )
		buildOutputPaths(plhs[0], plhs[1]);
}

void mexCmd_edgeCost(int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[])
{
	if ( nlhs != 1 )
		mexErrMsgTxt("edgeCost: Expect 1 outputs outcost.");

	if ( !gCostGraph )
		mexErrMsgTxt("edgeCost: Cost graph must first be initialized. Run \"initGraph\" command.");

	if ( nrhs < 2 || !mxIsClass(prhs[1], "double") || mxGetNumberOfElements(prhs[1]) != 1 )
		mexErrMsgTxt("edgeCost: Expected scalar start vertex index as second parameter.");

	if ( nrhs < 3 || !mxIsClass(prhs[2], "double") || mxGetNumberOfElements(prhs[2]) != 1 )
		mexErrMsgTxt("edgeCost: Expected scalar end vertex index as third parameter.");

	mwIndex startVert = ((mwIndex) mxGetScalar(prhs[1]));
	mwIndex endVert = ((mwIndex) mxGetScalar(prhs[2]));

	plhs[0] = mxCreateNumericMatrix(1,1, mxDOUBLE_CLASS, mxREAL);
	double* costData = (double*) mxGetData(plhs[0]);
	
	double edgeCost = gCostGraph->findEdge(startVert, endVert);
	if ( edgeCost == CSparseWrapper::noEdge )
		(*costData) = 0.0;
	else
		(*costData) = edgeCost;
}

void mexCmd_debugEdgesIn(int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[])
{
	if ( nlhs != 2 )
		mexErrMsgTxt("debugEdgesIn: Expect 2 outputs [outverts outcosts].");

	if ( !gCostGraph )
		mexErrMsgTxt("debugEdgesIn: Cost graph must first be initialized. Run \"initGraph\" command.");

	if ( nrhs < 2 || !mxIsClass(prhs[1], "double") || mxGetNumberOfElements(prhs[1]) != 1 )
		mexErrMsgTxt("debugEdgesIn: Expected scalar vertex index as second parameter.");

	mwIndex nextVert = ((mwIndex) mxGetScalar(prhs[1]));

	int numEdges = gCostGraph->getInEdgeLength(nextVert);

	plhs[0] = mxCreateNumericMatrix(1, numEdges, mxDOUBLE_CLASS, mxREAL);
	plhs[1] = mxCreateNumericMatrix(1, numEdges, mxDOUBLE_CLASS, mxREAL);

	double* edgeData = (double*) mxGetData(plhs[0]);
	double* costData = (double*) mxGetData(plhs[1]);

	CSparseWrapper::tEdgeIterator edgeIter = gCostGraph->getInEdgeIter(nextVert);
	for ( int i=0; i < numEdges; ++i, ++edgeIter )
	{
		edgeData[i] = edgeIter->first;
		costData[i] = edgeIter->second;
	}
}

void mexCmd_debugEdgesOut(int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[])
{
	if ( nlhs != 2 )
		mexErrMsgTxt("debugEdgesOut: Expect 2 outputs [outverts outcosts].");

	if ( !gCostGraph )
		mexErrMsgTxt("debugEdgesOut: Cost graph must first be initialized. Run \"initGraph\" command.");

	if ( nrhs < 2 || !mxIsClass(prhs[1], "double") || mxGetNumberOfElements(prhs[1]) != 1 )
		mexErrMsgTxt("debugEdgesOut: Expected scalar vertex index as second parameter.");

	mwIndex startVert = ((mwIndex) mxGetScalar(prhs[1]));

	int numEdges = gCostGraph->getOutEdgeLength(startVert);

	plhs[0] = mxCreateNumericMatrix(1, numEdges, mxDOUBLE_CLASS, mxREAL);
	plhs[1] = mxCreateNumericMatrix(1, numEdges, mxDOUBLE_CLASS, mxREAL);

	double* edgeData = (double*) mxGetData(plhs[0]);
	double* costData = (double*) mxGetData(plhs[1]);

	CSparseWrapper::tEdgeIterator edgeIter = gCostGraph->getOutEdgeIter(startVert);
	for ( int i=0; i < numEdges; ++i, ++edgeIter )
	{
		edgeData[i] = edgeIter->first;
		costData[i] = edgeIter->second;
	}
}

void mexCmd_debugTestFunc(int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[])
{
	if ( nlhs > 0 )
		mexErrMsgTxt("debugTestFunc: Output values unsupported.");

	if ( nrhs < 2 || !mxIsClass(prhs[1], "function_handle") )
		mexErrMsgTxt("debugTestFunc: Expected function handle as first parameter.");

	if ( nrhs < 3 || !mxIsClass(prhs[2], "double") || mxGetNumberOfElements(prhs[2]) != 1 )
		mexErrMsgTxt("debugTestFunc: Expected scalar start vertex index as second parameter.");

	if ( nrhs < 4 || !mxIsClass(prhs[3], "double") || mxGetNumberOfElements(prhs[3]) != 1 )
		mexErrMsgTxt("debugTestFunc: Expected scalar end vertex index as third parameter.");

	const mxArray* acceptFuncHandle = prhs[1];
	mwIndex startVert = ((mwIndex) mxGetScalar(prhs[2]));
	mwIndex endVert = ((mwSize) mxGetScalar(prhs[3]));

	mxArray* nprhs[1] = {(mxArray*) acceptFuncHandle};

	bool result = callMatlabAcceptFunc(acceptFuncHandle, startVert, endVert);

	if ( result == true )
		mexPrintf("\tFunction evaluated to true for (%d,%d)\n", startVert, endVert);
	else
		mexPrintf("\tFunction evaluated to false for (%d,%d)\n", startVert, endVert);
}


// Main entry point
void mexFunction(int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[])
{
	if ( nrhs < 1 )
		mexErrMsgTxt("Function requires a command string as first argument.");

	if ( !mxIsClass(prhs[0], "char") )
		mexErrMsgTxt("Parameter 1 must be a command string.");

	char* commandStr = mxArrayToString(prhs[0]);

	if ( IS_COMMAND(commandStr, initGraph) )
	{
		CALL_COMMAND(initGraph);
	}
	else if ( IS_COMMAND(commandStr, checkExtension) )
	{
		CALL_COMMAND(checkExtension);
	}
	else if ( IS_COMMAND(commandStr, matlabExtend) )
	{
		CALL_COMMAND(matlabExtend);
	}
	else if ( IS_COMMAND(commandStr, edgeCost) )
	{
		CALL_COMMAND(edgeCost);
	}

	else if ( IS_COMMAND(commandStr, debugEdgesOut) )
	{
		CALL_COMMAND(debugEdgesOut);
	}
	else if ( IS_COMMAND(commandStr, debugEdgesIn) )
	{
		CALL_COMMAND(debugEdgesIn);
	}
	else if ( IS_COMMAND(commandStr, debugTestFunc) )
	{
		CALL_COMMAND(debugTestFunc);
	}
	else
	{
		mexPrintf("Invalid Command String: \"%s\"\n\n", commandStr);
		mexPrintf("Supported Commands:\n");
		mexPrintf("\t initGraph(costMatrix) - Initialize the mex routines with a sparse matrix costMatrix.\n");
		mexPrintf("\t checkExtension(startVert, maxLength) - Find suitable extensions out to maxLength from startVert.\n");
		mexPrintf("\t matlabExtend(startVert, maxLength, acceptFunc) - Find suitable extensions using matlab acceptFunc as acceptance criterion.\n");
		mexPrintf("\t edgeCost(startVert, nextVert) - Return cost for given edge (0.0) if no edge exists.\n");
	}

	mxFree(commandStr);

	return;
}
