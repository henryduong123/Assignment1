#include "UpdateDistancesThreaded.h"
#include "mexCCDistance.h"
#include "Helpers.h"
#include "DistanceCalc_ispc.h"

#include <set>

//#pragma optimize("",off)
DWORD WINAPI UpdateDistancesThreaded(LPVOID lpParam)
{
	updateData* in = (updateData*)lpParam;
	if (in->nextFrame <1 || in->nextFrame>gHashedCellsLcl.size())
		return 0;

	int timeDif = abs(in->nextFrame-in->frameOfCell);

	double comLimit = SQR(timeDif*gmaxDisCOM);

	// get a list of hulls to consider
	int numNextCells = (int)gHashedCellsLcl[MATLAB_TO_C(in->nextFrame)].size();
	double* xComs = new double[numNextCells];
	double* yComs = new double[numNextCells];
	double* dists = new double[numNextCells];

	std::set<int>::iterator nextCell = gHashedCellsLcl[MATLAB_TO_C(in->nextFrame)].begin();
	for (int i=0; nextCell!=gHashedCellsLcl[MATLAB_TO_C(in->nextFrame)].end(); ++nextCell, ++i)
	{
		xComs[i] = gCellHullsLcl[MATLAB_TO_C(*nextCell)].centerOfMass[0];
		yComs[i] = gCellHullsLcl[MATLAB_TO_C(*nextCell)].centerOfMass[1];
	}

	ispc::DistanceCalc(gCellHullsLcl[MATLAB_TO_C(in->cellID)].centerOfMass[0],gCellHullsLcl[MATLAB_TO_C(in->cellID)].centerOfMass[1],
		xComs,yComs,numNextCells,dists);

	std::vector<int> closeCells;
	closeCells.reserve(numNextCells);
	nextCell = gHashedCellsLcl[MATLAB_TO_C(in->nextFrame)].begin();
	for (int i=0; i<numNextCells; ++i, ++nextCell)
	{
		if (dists[i] <= comLimit)
			closeCells.push_back(*nextCell);
	}

	for (int i=0; i<closeCells.size(); ++i)
	{
		int numIntersect = 0;
		std::set<int>::iterator indPixels = gCellHullsLcl[MATLAB_TO_C(closeCells[i])].pixelindices.begin();
		for (; indPixels!=gCellHullsLcl[MATLAB_TO_C(closeCells[i])].pixelindices.end(); ++indPixels)
			numIntersect += (int)gCellHullsLcl[MATLAB_TO_C(in->cellID)].pixelindices.count(*indPixels);

		// If there is overlap, set the distance based on how many overlap
		if (numIntersect>0)
		{
			double dist = 1 - (double)numIntersect/std::min<int>(
				(int)gCellHullsLcl[MATLAB_TO_C(in->cellID)].pixelindices.size(),(int)gCellHullsLcl[MATLAB_TO_C(closeCells[i])].pixelindices.size());
			SetDistance(in->cellID,closeCells[i],dist,in->nextFrame-in->frameOfCell);
			continue;
		}

		// Cells don't overlap, set the distance based on the closest two pixels
		double ccMinDistSq = std::numeric_limits<double>::infinity();
		for (int j=0; j<gCellHullsLcl[MATLAB_TO_C(in->cellID)].pixelindices.size(); ++j)
		{
			int numNextPixels = (int)gCellHullsLcl[MATLAB_TO_C(closeCells[i])].pixelindices.size();
			double* distsNext = new double[numNextPixels];

			ispc::DistanceCalc(gCellHullsLcl[MATLAB_TO_C(in->cellID)].xPixels[j],gCellHullsLcl[MATLAB_TO_C(in->cellID)].yPixels[j],
				gCellHullsLcl[MATLAB_TO_C(closeCells[i])].xPixels,gCellHullsLcl[MATLAB_TO_C(closeCells[i])].yPixels,numNextPixels,distsNext);

			for (int k=0; k<numNextPixels; ++k)
			{
				if (distsNext[k]<ccMinDistSq)
					ccMinDistSq = distsNext[k];
			}

			delete[] distsNext;
		}
		double ccMaxDistTemp = ccMaxDist;
		if (timeDif!=1)
			ccMaxDistTemp = ccMaxDist * 1.5;

		if (ccMinDistSq > SQR(ccMaxDistTemp))
			continue;

		SetDistance(in->cellID,closeCells[i],sqrt(ccMinDistSq),in->nextFrame-in->frameOfCell);
	}

	delete[] xComs;
	delete[] yComs;
	delete[] dists;

	return 0;
}