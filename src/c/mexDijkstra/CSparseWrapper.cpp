#include "mexDijkstra.h"
#include "CSparseWrapper.h"

const double CSparseWrapper::noEdge = std::numeric_limits<double>::infinity();

CSparseWrapper::CSparseWrapper(const mxArray* sparseArray)
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

int CSparseWrapper::getOutEdgeLength(mwIndex startVert)
{
	return outEdges[MATLAB_IDX(startVert)].size();
}
CSparseWrapper::tEdgeIterator CSparseWrapper::getOutEdgeIter(mwIndex startVert)
{
	return outEdges[MATLAB_IDX(startVert)].begin();
}

int CSparseWrapper::getInEdgeLength(mwIndex nextVert)
{
	return inEdges[MATLAB_IDX(nextVert)].size();
}
CSparseWrapper::tEdgeIterator CSparseWrapper::getInEdgeIter(mwIndex nextVert)
{
	return inEdges[MATLAB_IDX(nextVert)].begin();
}

double CSparseWrapper::findEdge(mwIndex startVert, mwIndex nextVert)
{
	if ( outEdges[MATLAB_IDX(startVert)].count(nextVert) < 1 )
		return CSparseWrapper::noEdge;

	return (outEdges[MATLAB_IDX(startVert)][nextVert]);
}