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

#include "mexGraph.h"
#include "CSparseWrapper.h"

#include <vector>
#include <set>
#include <map>
#include <list>

#include <string.h>

#define ARRAY_SIZE(x) (sizeof(x) / sizeof((x)[0]))

// Couple of convenience macros for command handling
//#define DEFINE_COMMAND(cmdname) void mexCmd##cmdname(int nrhs, mxArray* prhs, int nlhs, const mxArray* plhs)
#define IS_COMMAND(value,cmdname) (strcmpi((value),(#cmdname)) == 0)
#define CALL_COMMAND(cmdname) {mexCmd_##cmdname(nlhs, plhs, nrhs, prhs);}

// Globals
std::set<CSparseGraph*> gGraphs;

void mexCmd_deleteGraph(int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[])
{
	if ( nlhs > 0 )
		mexErrMsgTxt("deleteGraph: Outputs unsupported.");

	int argSize = mxGetNumberOfElements(prhs[1]);
	if ( nrhs < 2 || !mxIsClass(prhs[1], "double") || (mxGetNumberOfElements(prhs[1]) != 1) )
		mexErrMsgTxt("deleteGraph: Expected graph handle.");

	CSparseGraph* chkGraph = ((CSparseGraph**) mxGetData(prhs[1]))[0];
	if ( !gGraphs.count(chkGraph) )
		mexErrMsgTxt("deleteGraph: Cost graph must first be initialized. Run \"initGraph\" command.");

	delete chkGraph;
}

void mexCmd_createGraph(int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[])
{
	if ( nlhs != 1 )
		mexErrMsgTxt("initGraph: Only single output value supported.");

	int argSize = mxGetNumberOfElements(prhs[1]);
	if ( nrhs < 2 || !mxIsClass(prhs[1], "double") || (mxGetNumberOfElements(prhs[1]) != 1) )
		mexErrMsgTxt("initGraph: Expected number of vertices.");

	mwSize numVerts = (mwSize) mxGetScalar(prhs[1]);

	CSparseGraph* newGraph = new CSparseGraph(numVerts);

	gGraphs.insert(newGraph);

	plhs[0] = mxCreateNumericMatrix(1,1, mxDOUBLE_CLASS, mxREAL);
	double* costData = (double*) mxGetData(plhs[0]);
	costData[0] = *((double*) &newGraph);
}

void mexCmd_createInitGraph(int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[])
{
	if ( nlhs != 1 )
		mexErrMsgTxt("initGraph: Only single output value supported.");

	if ( nrhs < 2 || !mxIsClass(prhs[1], "double") || !mxIsSparse(prhs[1]) )
		mexErrMsgTxt("initGraph: Expected sparse matrix graph as second parameter.");

	CSparseGraph* newGraph = new CSparseGraph(prhs[1]);

	gGraphs.insert(newGraph);

	plhs[0] = mxCreateNumericMatrix(1,1, mxDOUBLE_CLASS, mxREAL);
	double* costData = (double*) mxGetData(plhs[0]);
	costData[0] = *((double*) &newGraph);
}

void mexCmd_updateGraph(int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[])
{
	if ( nlhs > 0 )
		mexErrMsgTxt("updateGraph: Expect no output arguments.");

	if ( nrhs < 2 )
		mexErrMsgTxt("updateGraph: Expect at least 2 arguments.");

	CSparseGraph* chkGraph = ((CSparseGraph**) mxGetData(prhs[1]))[0];
	if ( !gGraphs.count(chkGraph) )
		mexErrMsgTxt("updateGraph: Cost graph must first be initialized. Run \"initGraph\" command.");

	if ( nrhs < 3 || !mxIsClass(prhs[2], "double") )
		mexErrMsgTxt("updateGraph: Expected double cost matrix as third parameter.");

	mwSize m = mxGetM(prhs[2]);
	mwSize n = mxGetN(prhs[2]);

	if ( m < 1 || n < 1 )
		mexErrMsgTxt("updateGraph: Expected non-empty cost matrix as second parameter.");

	if ( nrhs < 4 || !mxIsClass(prhs[3], "double") || mxGetNumberOfElements(prhs[2]) != m )
		mexErrMsgTxt("updateGraph: Expected fromHulls list as fourth parameter.");

	if ( nrhs < 5 || !mxIsClass(prhs[4], "double") || mxGetNumberOfElements(prhs[3]) != n )
		mexErrMsgTxt("updateGraph: Expected fromHulls list as fifth parameter.");

	chkGraph->updateEdges(prhs[2], prhs[3], prhs[4]);
}

void mexCmd_removeEdges(int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[])
{
	if ( nlhs != 0 )
		mexErrMsgTxt("removeEdges: Output values unsupported.");

	if ( nrhs < 2 )
		mexErrMsgTxt("removeEdges: Expect at least 2 arguments.");

	CSparseGraph* chkGraph = ((CSparseGraph**) mxGetData(prhs[1]))[0];
	if ( !gGraphs.count(chkGraph) )
		mexErrMsgTxt("removeEdges: Cost graph must first be initialized. Run \"initGraph\" command.");

	if ( nrhs < 3 || !mxIsClass(prhs[2], "double"))
		mexErrMsgTxt("removeEdges: Expected start vertex list as second parameter.");

	if ( nrhs < 4 || !mxIsClass(prhs[3], "double"))
		mexErrMsgTxt("removeEdges: Expected end vertex list as third parameter.");

	mwSize startListSize = mxGetNumberOfElements(prhs[2]);
	mwSize endListSize = mxGetNumberOfElements(prhs[3]);

	if ( startListSize == 0 && endListSize == 0 )
		return;

	if ( startListSize == 0 )
	{
		double* endVertData = (double*) mxGetData(prhs[3]);
		for ( int i=0; i < endListSize; ++i )
			chkGraph->removeAllInEdges((mwIndex) endVertData[C_IDX(i)]);

		return;
	}

	if ( endListSize == 0 )
	{
		double* startVertData = (double*) mxGetData(prhs[2]);
		for ( int i=0; i < startListSize; ++i )
			chkGraph->removeAllOutEdges((mwIndex) startVertData[C_IDX(i)]);

		return;
	}

	if ( startListSize != endListSize )
		mexErrMsgTxt("removeEdges: Start and End vertex lists must be same size (or empty).");

	double* startVertData = (double*) mxGetData(prhs[2]);
	double* endVertData = (double*) mxGetData(prhs[3]);

	for ( int i=0; i < startListSize; ++i )
		chkGraph->removeEdge((mwIndex) startVertData[C_IDX(i)], (mwIndex) endVertData[C_IDX(i)]);
}

void mexCmd_getEdge(int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[])
{
	if ( nlhs != 1 )
		mexErrMsgTxt("getCost: Expect 1 output.");

	if ( nrhs < 2 )
		mexErrMsgTxt("getCost: Expect at least 2 arguments.");

	CSparseGraph* chkGraph = ((CSparseGraph**) mxGetData(prhs[1]))[0];
	if ( !gGraphs.count(chkGraph) )
		mexErrMsgTxt("getCost: Cost graph must first be initialized. Run \"initGraph\" command.");

	if ( nrhs < 3 || !mxIsClass(prhs[2], "double") || mxGetNumberOfElements(prhs[2]) != 1 )
		mexErrMsgTxt("getCost: Expected scalar start vertex index as third parameter.");

	if ( nrhs < 4 || !mxIsClass(prhs[3], "double") || mxGetNumberOfElements(prhs[3]) != 1 )
		mexErrMsgTxt("getCost: Expected scalar end vertex index as fourth parameter.");

	mwIndex startVert = ((mwIndex) mxGetScalar(prhs[2]));
	mwIndex endVert = ((mwIndex) mxGetScalar(prhs[3]));

	plhs[0] = mxCreateNumericMatrix(1,1, mxDOUBLE_CLASS, mxREAL);
	double* costData = (double*) mxGetData(plhs[0]);
	
	double edgeCost = chkGraph->findEdge(startVert, endVert);
	//if ( edgeCost == CSparseGraph::noEdge )
	//	(*costData) = 0.0;
	//else
		(*costData) = edgeCost;
}

void mexCmd_setEdge(int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[])
{
	if ( nlhs > 0 )
		mexErrMsgTxt("setEdge: Expect 0 outputs.");

	if ( nrhs < 2 )
		mexErrMsgTxt("setEdge: Expect at least 2 arguments.");

	CSparseGraph* chkGraph = ((CSparseGraph**) mxGetData(prhs[1]))[0];
	if ( !gGraphs.count(chkGraph) )
		mexErrMsgTxt("setEdge: Cost graph must first be initialized. Run \"initGraph\" command.");

	if ( nrhs < 3 || !mxIsClass(prhs[2], "double") || mxGetNumberOfElements(prhs[2]) != 1 )
		mexErrMsgTxt("setEdge: Expected scalar start vertex index as third parameter.");

	if ( nrhs < 4 || !mxIsClass(prhs[3], "double") || mxGetNumberOfElements(prhs[3]) != 1 )
		mexErrMsgTxt("setEdge: Expected scalar end vertex index as fourth parameter.");

	if ( nrhs < 5 || !mxIsClass(prhs[4], "double") || mxGetNumberOfElements(prhs[4]) != 1 )
		mexErrMsgTxt("setEdge: Expected scalar end vertex index as fifth parameter.");

	mwIndex startVert = ((mwIndex) mxGetScalar(prhs[2]));
	mwIndex endVert = ((mwIndex) mxGetScalar(prhs[3]));
	
	double newCost = mxGetScalar(prhs[4]);
	chkGraph->setEdge(startVert, endVert, newCost);
}

void mexCmd_setEdgesOut(int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[])
{
	if ( nlhs > 0 )
		mexErrMsgTxt("setEdgesOut: Expect 0 outputs.");

	if ( nrhs < 2 )
		mexErrMsgTxt("setEdgesOut: Expect at least 2 arguments.");

	CSparseGraph* chkGraph = ((CSparseGraph**) mxGetData(prhs[1]))[0];
	if ( !gGraphs.count(chkGraph) )
		mexErrMsgTxt("setEdgesOut: Cost graph must first be initialized. Run \"initGraph\" command.");

	if ( nrhs < 3 || !mxIsClass(prhs[2], "double") || mxGetNumberOfElements(prhs[2]) != 1 )
		mexErrMsgTxt("setEdgesOut: Expected scalar start vertex index as third parameter.");

	if ( nrhs < 4 || !mxIsClass(prhs[3], "double") )
		mexErrMsgTxt("setEdgesOut: Expected end vertex list as fourth parameter.");

	if ( nrhs < 5 || !mxIsClass(prhs[4], "double") )
		mexErrMsgTxt("setEdgesOut: Expected edge values as fifth parameter");

	mwSize numEndVerts = mxGetNumberOfElements(prhs[3]);
	mwSize numEdgeCosts = mxGetNumberOfElements(prhs[4]);

	if ( numEndVerts != numEdgeCosts )
		mexErrMsgTxt("setEdgesOut: size of end vert list not equal to size of edge values");

	mwIndex startVert = ((mwIndex) mxGetScalar(prhs[2]));
	double* endVerts = ((double*) mxGetData(prhs[3]));
	double* newCosts = ((double*) mxGetData(prhs[4]));

	for ( int i=0; i < numEdgeCosts; ++i )
		chkGraph->setEdge(startVert, ((mwIndex) endVerts[i]), newCosts[i]);
}

void mexCmd_setEdgesIn(int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[])
{
	if ( nlhs > 0 )
		mexErrMsgTxt("setEdgesIn: Expect 0 outputs.");

	if ( nrhs < 2 )
		mexErrMsgTxt("setEdgesIn: Expect at least 2 arguments.");

	CSparseGraph* chkGraph = ((CSparseGraph**) mxGetData(prhs[1]))[0];
	if ( !gGraphs.count(chkGraph) )
		mexErrMsgTxt("setEdgesIn: Cost graph must first be initialized. Run \"initGraph\" command.");

	if ( nrhs < 3 || !mxIsClass(prhs[2], "double") )
		mexErrMsgTxt("setEdgesIn: Expected start vertex list as third parameter.");

	if ( nrhs < 4 || !mxIsClass(prhs[3], "double") || mxGetNumberOfElements(prhs[3]) != 1 )
		mexErrMsgTxt("setEdgesIn: Expected scalar end vertex index as fourth parameter.");

	if ( nrhs < 5 || !mxIsClass(prhs[4], "double") )
		mexErrMsgTxt("setEdgesIn: Expected edge values as fifth parameter");

	mwSize numStartVerts = mxGetNumberOfElements(prhs[2]);
	mwSize numEdgeCosts = mxGetNumberOfElements(prhs[4]);

	if ( numStartVerts != numEdgeCosts )
		mexErrMsgTxt("setEdgesIn: size of start vert list not equal to size of edge values");

	double* startVerts = ((double*) mxGetData(prhs[2]));
	mwIndex endVert = ((mwIndex) mxGetScalar(prhs[3]));
	double* newCosts = ((double*) mxGetData(prhs[4]));

	for ( int i=0; i < numEdgeCosts; ++i )
		chkGraph->setEdge(((mwIndex) startVerts[i]), endVert, newCosts[i]);
}

void mexCmd_edgesIn(int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[])
{
	if ( nlhs != 2 )
		mexErrMsgTxt("edgesIn: Expect 2 outputs [outverts outcosts].");

	if ( nrhs < 2 )
		mexErrMsgTxt("edgesIn: Expect at least 2 arguments.");

	CSparseGraph* chkGraph = ((CSparseGraph**) mxGetData(prhs[1]))[0];
	if ( !gGraphs.count(chkGraph) )
		mexErrMsgTxt("edgesIn: Cost graph must first be initialized. Run \"initGraph\" command.");

	if ( nrhs < 3 || !mxIsClass(prhs[2], "double") || mxGetNumberOfElements(prhs[2]) != 1 )
		mexErrMsgTxt("edgesIn: Expected scalar vertex index as third parameter.");

	mwIndex nextVert = ((mwIndex) mxGetScalar(prhs[2]));

	int numEdges = chkGraph->getInEdgeLength(nextVert);

	plhs[0] = mxCreateNumericMatrix(1, numEdges, mxDOUBLE_CLASS, mxREAL);
	plhs[1] = mxCreateNumericMatrix(1, numEdges, mxDOUBLE_CLASS, mxREAL);

	double* edgeData = (double*) mxGetData(plhs[0]);
	double* costData = (double*) mxGetData(plhs[1]);

	CSparseGraph::tEdgeIterator edgeIter = chkGraph->getInEdgeIter(nextVert);
	for ( int i=0; i < numEdges; ++i, ++edgeIter )
	{
		edgeData[i] = edgeIter->first;
		costData[i] = edgeIter->second;
	}
}

void mexCmd_edgesOut(int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[])
{
	if ( nlhs != 2 )
		mexErrMsgTxt("edgesOut: Expect 2 outputs [outverts outcosts].");

	if ( nrhs < 2 )
		mexErrMsgTxt("edgesOut: Expect at least 2 arguments.");

	CSparseGraph* chkGraph = ((CSparseGraph**) mxGetData(prhs[1]))[0];
	if ( !gGraphs.count(chkGraph) )
		mexErrMsgTxt("edgesOut: Cost graph must first be initialized. Run \"initGraph\" command.");

	if ( nrhs < 3 || !mxIsClass(prhs[2], "double") || mxGetNumberOfElements(prhs[2]) != 1 )
		mexErrMsgTxt("edgesOut: Expected scalar vertex index as third parameter.");

	mwIndex startVert = ((mwIndex) mxGetScalar(prhs[2]));

	int numEdges = chkGraph->getOutEdgeLength(startVert);

	plhs[0] = mxCreateNumericMatrix(1, numEdges, mxDOUBLE_CLASS, mxREAL);
	plhs[1] = mxCreateNumericMatrix(1, numEdges, mxDOUBLE_CLASS, mxREAL);

	double* edgeData = (double*) mxGetData(plhs[0]);
	double* costData = (double*) mxGetData(plhs[1]);

	CSparseGraph::tEdgeIterator edgeIter = chkGraph->getOutEdgeIter(startVert);
	for ( int i=0; i < numEdges; ++i, ++edgeIter )
	{
		edgeData[i] = edgeIter->first;
		costData[i] = edgeIter->second;
	}
}

void mexCmd_debugAllEdges(int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[])
{
	if ( nlhs != 2 )
		mexErrMsgTxt("debugAllEdges: Expect 2 outputs.");

	if ( nrhs < 2 )
		mexErrMsgTxt("debugEdgesIn: Expect at least 2 arguments.");

	CSparseGraph* chkGraph = ((CSparseGraph**) mxGetData(prhs[1]))[0];
	if ( !gGraphs.count(chkGraph) )
		mexErrMsgTxt("debugEdgesIn: Cost graph must first be initialized. Run \"initGraph\" command.");

	plhs[0] = mxCreateNumericMatrix(chkGraph->getNumEdges(), 3, mxDOUBLE_CLASS, mxREAL);
	plhs[1] = mxCreateNumericMatrix(chkGraph->getNumEdges(), 3, mxDOUBLE_CLASS, mxREAL);

	char errMsg[1024];

	mwSize numTotalEdges = chkGraph->getNumEdges();
	double* outEdgeData = (double*) mxGetData(plhs[0]);

	int visitedEdges = 0;
	for ( int i=0; i < chkGraph->getNumVerts(); ++i )
	{
		int startVert = i+1;
		int numOutEdges = chkGraph->getOutEdgeLength(startVert);
		CSparseGraph::tEdgeIterator edgeIter = chkGraph->getOutEdgeIter(startVert);

		for ( int j=0; j < numOutEdges; ++j, ++edgeIter )
		{
			outEdgeData[visitedEdges] = startVert;
			outEdgeData[numTotalEdges + visitedEdges] = edgeIter->first;
			outEdgeData[2*numTotalEdges + visitedEdges] = edgeIter->second;

			++visitedEdges;
			//if ( visitedEdges > numTotalEdges )
			//{
			//	sprintf(errMsg, "Expected %d out edges, visited %d", numTotalEdges, visitedEdges);
			//	mexErrMsgTxt(errMsg);
			//}
		}
	}

	if ( visitedEdges != numTotalEdges )
	{
		sprintf(errMsg, "Expected %d out edges, visited %d", numTotalEdges, visitedEdges);
		mexErrMsgTxt(errMsg);
	}


	double* inEdgeData = (double*) mxGetData(plhs[1]);

	visitedEdges = 0;
	for ( int i=0; i < chkGraph->getNumVerts(); ++i )
	{
		int nextVert = i+1;
		int numOutEdges = chkGraph->getInEdgeLength(nextVert);
		CSparseGraph::tEdgeIterator edgeIter = chkGraph->getInEdgeIter(nextVert);

		for ( int j=0; j < numOutEdges; ++j, ++edgeIter )
		{
			inEdgeData[visitedEdges] = edgeIter->first;
			inEdgeData[numTotalEdges + visitedEdges] = nextVert;
			inEdgeData[2*numTotalEdges + visitedEdges] = edgeIter->second;

			++visitedEdges;
			//if ( visitedEdges > numTotalEdges )
			//{
			//	sprintf(errMsg, "Expected %d in edges, visited %d", numTotalEdges, visitedEdges);
			//	mexErrMsgTxt(errMsg);
			//}
		}
	}

	if ( visitedEdges != numTotalEdges )
	{
		sprintf(errMsg, "Expected %d in edges, visited %d", numTotalEdges, visitedEdges);
		mexErrMsgTxt(errMsg);
	}
}

// Main entry point
void mexFunction(int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[])
{
	if ( nrhs < 1 )
		mexErrMsgTxt("Function requires a command string as first argument.");

	if ( !mxIsClass(prhs[0], "char") )
		mexErrMsgTxt("Parameter 1 must be a command string.");

	char* commandStr = mxArrayToString(prhs[0]);

	if ( IS_COMMAND(commandStr, createGraph) )
	{
		CALL_COMMAND(createGraph);
	}
	else if ( IS_COMMAND(commandStr, createInitGraph) )
	{
		CALL_COMMAND(createInitGraph);
	}
	else if ( IS_COMMAND(commandStr, deleteGraph) )
	{
		CALL_COMMAND(deleteGraph);
	}
	else if ( IS_COMMAND(commandStr, updateGraph) )
	{
		CALL_COMMAND(updateGraph);
	}
	else if ( IS_COMMAND(commandStr, removeEdges) )
	{
		CALL_COMMAND(removeEdges);
	}
	else if ( IS_COMMAND(commandStr, getEdge) )
	{
		CALL_COMMAND(getEdge);
	}
	else if ( IS_COMMAND(commandStr, setEdge) )
	{
		CALL_COMMAND(setEdge);
	}
	else if ( IS_COMMAND(commandStr, setEdgesOut) )
	{
		CALL_COMMAND(setEdgesOut);
	}
	else if ( IS_COMMAND(commandStr, setEdgesIn) )
	{
		CALL_COMMAND(setEdgesIn);
	}
	else if ( IS_COMMAND(commandStr, edgesOut) )
	{
		CALL_COMMAND(edgesOut);
	}
	else if ( IS_COMMAND(commandStr, edgesIn) )
	{
		CALL_COMMAND(edgesIn);
	}

	else if ( IS_COMMAND(commandStr, debugAllEdges) )
	{
		CALL_COMMAND(debugAllEdges);
	}
	else
	{
		mexPrintf("Invalid Command String: \"%s\"\n\n", commandStr);
		mexPrintf("Supported Commands:\n");
		mexPrintf("\t initGraph(costMatrix) - Initialize the mex routines with a sparse matrix costMatrix.\n");
		mexPrintf("\t updateGraph(costMatrix, fromHulls, toHulls) - Update internal cost edges using costMatrix and from/to hulls lists");
		mexPrintf("\t removeEdges(startVertList, endVertList) - Remove all edges in list.\n");
		mexPrintf("\t edgeCost(startVert, nextVert) - Return cost for given edge Inf if no edge exists.\n");
		mexPrintf("\t edgesIn(nextVert) - Return index and cost of incoming edges.\n");
		mexPrintf("\t edgesOut(startVert) - Return index and cost of outgoing edges.\n");
	}

	mxFree(commandStr);

	return;
}
