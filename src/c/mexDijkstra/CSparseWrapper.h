

/***********************************************************************
*     Copyright 2011-2016 Drexel University
*
*     This file is part of LEVer - the tool for stem cell lineaging. See
*     http://n2t.net/ark:/87918/d9rp4t for details
* 
*     LEVer is free software: you can redistribute it and/or modify
*     it under the terms of the GNU General Public License as published by
*     the Free Software Foundation, either version 3 of the License, or
*     (at your option) any later version.
* 
*     LEVer is distributed in the hope that it will be useful,
*     but WITHOUT ANY WARRANTY; without even the implied warranty of
*     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*     GNU General Public License for more details.
* 
*     You should have received a copy of the GNU General Public License
*     along with LEVer in file "gnu gpl v3.txt".  If not, see 
*     <http://www.gnu.org/licenses/>.
*
***********************************************************************/

#ifndef CSPARSEWRAPPER_H
#define CSPARSEWRAPPER_H 1

#include <limits>
#include <vector>
#include <map>

class CSparseWrapper
{
public:
	typedef std::map<mwIndex, double>::iterator tEdgeIterator;

	static const double noEdge;

	CSparseWrapper(const mxArray* sparseArray);
	//~CSparseWrapper();

	mwSize getNumVerts()
	{
		return numVerts;
	}

	mwSize getNumEdges()
	{
		return numEdges;
	}

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