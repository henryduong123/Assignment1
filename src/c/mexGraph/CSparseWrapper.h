#ifndef CSPARSEWRAPPER_H
#define CSPARSEWRAPPER_H 1

#include <limits>
#include <vector>
#include <map>

class CSparseGraph
{
public:
	typedef std::map<mwIndex, double>::iterator tEdgeIterator;

	static const double noEdge;

	CSparseGraph::CSparseGraph(mwSize numHulls);
	CSparseGraph(const mxArray* sparseArray);
	//~CSparseWrapper();

	mwSize getNumVerts()
	{
		return numVerts;
	}

	mwSize getNumEdges()
	{
		return numEdges;
	}

	void setEdge(mwIndex startVert, mwIndex nextVert, double cost);
	void updateEdges(const mxArray* costs, const mxArray* fromHulls, const mxArray* toHulls);

	int getOutEdgeLength(mwIndex startVert);
	tEdgeIterator getOutEdgeIter(mwIndex startVert);

	int getInEdgeLength(mwIndex nextVert);
	tEdgeIterator getInEdgeIter(mwIndex nextVert);

	double findEdge(mwIndex startVert, mwIndex nextVert);

	void removeAllOutEdges(mwIndex startVert);
	void removeAllInEdges(mwIndex endVert);
	void removeEdge(mwIndex startVert, mwIndex endVert);

private:
	mwSize numVerts;
	mwSize numEdges;

	std::vector< std::map<mwIndex, double> > outEdges;
	std::vector< std::map<mwIndex, double> > inEdges;
};

#endif //CSPARSEWRAPPER_H