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
