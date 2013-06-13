#include "mexGraph.h"
#include "CSparseWrapper.h"

const double CSparseGraph::noEdge = std::numeric_limits<double>::infinity();

CSparseGraph::CSparseGraph(mwSize numHulls)
{
	numVerts = numHulls;
	numEdges = 0;

	outEdges.resize(numHulls);
	inEdges.resize(numHulls);
}

CSparseGraph::CSparseGraph(const mxArray* sparseArray)
{
	mwSize nzmax = mxGetNzmax(sparseArray);
	mwSize numRows = mxGetM(sparseArray);
	mwSize numCols = mxGetN(sparseArray);

	numVerts = numRows;
	numEdges = 0;

	mwIndex* mxjc = mxGetJc(sparseArray);
	mwIndex* mxir = mxGetIr(sparseArray);
	double* mxpr = mxGetPr(sparseArray);

	outEdges.resize(numRows);
	inEdges.resize(numCols);

	for ( mwIndex i=1; i <= numCols; ++i )
	{
		mwIndex numInEdges = mxjc[MATLAB_IDX(i+1)] - mxjc[MATLAB_IDX(i)];
		for ( mwIndex j=1; j <= numInEdges; ++j )
		{
			mwIndex dataIdx = mxjc[MATLAB_IDX(i)]+j;
			double edgeCost = mxpr[MATLAB_IDX(dataIdx)];
			if ( edgeCost == 0.0 )
				continue;

			mwIndex rowIdx = mxir[MATLAB_IDX(dataIdx)];
			outEdges[C_IDX(rowIdx)].insert(std::pair<mwIndex,double>(i,edgeCost));
			inEdges[MATLAB_IDX(i)].insert(std::pair<mwIndex,double>((rowIdx+1),edgeCost));

			++numEdges;
		}
	}
}

void CSparseGraph::updateEdges(const mxArray* costs, const mxArray* fromHulls, const mxArray* toHulls)
{
	mwSize numFrom = mxGetNumberOfElements(fromHulls);
	mwSize numTo = mxGetNumberOfElements(toHulls);

	double* fromHullData = mxGetPr(fromHulls);
	double* toHullData = mxGetPr(toHulls);

	mwIndex maxHull = 0;
	for ( mwIndex i=0; i < numFrom; ++i )
		maxHull = std::max<mwIndex>(maxHull, fromHullData[i]);

	for ( mwIndex i=0; i < numTo; ++i )
		maxHull = std::max<mwIndex>(maxHull, toHullData[i]);

	if ( (maxHull > numVerts) )
	{
		numVerts = maxHull;

		outEdges.resize(numVerts);
		inEdges.resize(numVerts);
	}

	double* costData = mxGetPr(costs);
	for ( mwIndex i=0; i < numFrom; ++i )
	{
		mwIndex matFromHull = fromHullData[i];
		for ( mwIndex j=0; j < numTo; ++j )
		{
			mwIndex matToHull = toHullData[j];
			double edgeCost = costData[i + j*numFrom];

			bool bEdgeExists = (outEdges[MATLAB_IDX(matFromHull)].count(matToHull) > 0);
			bool bDeleteEdge = (edgeCost == 0.0) || (edgeCost == CSparseGraph::noEdge);

			if ( bEdgeExists )
			{
				if ( bDeleteEdge )
				{
					outEdges[MATLAB_IDX(matFromHull)].erase(matToHull);
					inEdges[MATLAB_IDX(matToHull)].erase(matFromHull);
				}
				else
				{
					outEdges[MATLAB_IDX(matFromHull)][matToHull] = edgeCost;
					inEdges[MATLAB_IDX(matToHull)][matFromHull] = edgeCost;
				}
			}
			else if ( !bDeleteEdge )
			{
				outEdges[MATLAB_IDX(matFromHull)].insert(std::pair<mwIndex,double>(matToHull,edgeCost));
				inEdges[MATLAB_IDX(matToHull)].insert(std::pair<mwIndex,double>(matFromHull,edgeCost));
			}
		}
	}
}

int CSparseGraph::getOutEdgeLength(mwIndex startVert)
{
	return outEdges[MATLAB_IDX(startVert)].size();
}

CSparseGraph::tEdgeIterator CSparseGraph::getOutEdgeIter(mwIndex startVert)
{
	return outEdges[MATLAB_IDX(startVert)].begin();
}

int CSparseGraph::getInEdgeLength(mwIndex nextVert)
{
	return inEdges[MATLAB_IDX(nextVert)].size();
}

CSparseGraph::tEdgeIterator CSparseGraph::getInEdgeIter(mwIndex nextVert)
{
	return inEdges[MATLAB_IDX(nextVert)].begin();
}

void CSparseGraph::setEdge(mwIndex startVert, mwIndex nextVert, double cost)
{
	if ( outEdges[MATLAB_IDX(startVert)].count(nextVert) < 1 )
	{
		if ( (cost == 0.0) || (cost == CSparseGraph::noEdge) )
		{
			outEdges[MATLAB_IDX(startVert)].erase(nextVert);
			inEdges[MATLAB_IDX(nextVert)].erase(startVert);
			--numEdges;
		}

		outEdges[MATLAB_IDX(startVert)].insert(std::pair<mwIndex,double>(nextVert,cost));
		inEdges[MATLAB_IDX(nextVert)].insert(std::pair<mwIndex,double>(startVert,cost));

		++numEdges;
	}
	else
	{
		outEdges[MATLAB_IDX(startVert)][nextVert] = cost;
		inEdges[MATLAB_IDX(nextVert)][startVert] = cost;
	}

}

double CSparseGraph::findEdge(mwIndex startVert, mwIndex nextVert)
{
	if ( outEdges[MATLAB_IDX(startVert)].count(nextVert) < 1 )
		return CSparseGraph::noEdge;

	return (outEdges[MATLAB_IDX(startVert)][nextVert]);
}

void CSparseGraph::removeAllOutEdges(mwIndex startVert)
{
	int numOutEdges = getOutEdgeLength(startVert);
	tEdgeIterator outIter = getOutEdgeIter(startVert);

	for ( int i=0; i < numOutEdges; ++i,++outIter )
	{
		mwIndex nextVert = outIter->first;
		inEdges[MATLAB_IDX(nextVert)].erase(startVert);
	}

	outEdges[MATLAB_IDX(startVert)].clear();

	numEdges -= numOutEdges;
}

void CSparseGraph::removeAllInEdges(mwIndex endVert)
{
	int numInEdges = getInEdgeLength(endVert);
	tEdgeIterator inIter = getInEdgeIter(endVert);

	for ( int i=0; i < numInEdges; ++i,++inIter )
	{
		mwIndex startVert = inIter->first;
		outEdges[MATLAB_IDX(startVert)].erase(endVert);
	}

	inEdges[MATLAB_IDX(endVert)].clear();

	numEdges -= numInEdges;
}

void CSparseGraph::removeEdge(mwIndex startVert, mwIndex endVert)
{
	outEdges[MATLAB_IDX(startVert)].erase(endVert);
	inEdges[MATLAB_IDX(endVert)].erase(startVert);

	--numEdges;
}