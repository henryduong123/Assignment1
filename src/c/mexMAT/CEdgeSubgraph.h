/***********************************************************************
*     Copyright 2011-2016 Andrew Cohen
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
#ifndef _CEDGESUBGRAPH_H_
#define _CEDGESUBGRAPH_H_ 1

class CEdgeSubgraph
{
public:
	CEdgeSubgraph(mxArray* rows, mxArray* cols)
	{
		double* rdata = (double*) mxGetData(rows);
		int numRows = mxGetNumberOfElements(rows);

		double* cdata = (double*) mxGetData(cols);
		int numCols = mxGetNumberOfElements(cols);

		weights = mxCreateNumericMatrix(numRows, numCols, mxDOUBLE_CLASS, mxREAL);
		weightData = (double*) mxGetData(weights);

		for ( int i=0; i < numRows; ++i )
			rowToRIdx.insert(std::pair<int,int>(((int) rdata[i]), i));

		for ( int i=0; i < numCols; ++i )
			colToCIdx.insert(std::pair<int,int>(((int) cdata[i]), i));
	}

	double* getPtr(int r, int c)
	{
		// Should probably be a throw
		if ( !validEntry(r,c) )
			return NULL;

		int ridx = rowToRIdx[r];
		int cidx = colToCIdx[c];

		return &(weightData[ridx + rowToRIdx.size()*cidx]);
	}

	bool validEntry(int r, int c)
	{
		if ( rowToRIdx.count(r) == 0 )
			return false;

		if ( colToCIdx.count(c) == 0 )
			return false;

		return true;
	}

	int rows()
	{
		return rowToRIdx.size();
	}

	int columns()
	{
		return colToCIdx.size();
	}

	mxArray* graphPointer()
	{
		return weights;
	}

private:
	CEdgeSubgraph(){};

private:

	mxArray* weights;
	double* weightData;

	std::map<int,int> rowToRIdx;
	std::map<int,int> colToCIdx;
};

#endif
