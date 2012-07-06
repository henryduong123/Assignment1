#include "UpdateDistances.h"
#include "Helpers.h"
#include "mexCCDistance.h"
#include "DistanceCalc_ispc.h"

#include <vector>
#include <set>

void UpdateDistances(int hullID, int frameOfCell, int nextFrame)
{
	if (nextFrame <1 || nextFrame>mxGetNumberOfElements(gHashedCells))
		return;

	int timeDif = abs(nextFrame-frameOfCell);

	std::vector<int> nextCells;
	mxArray* mp_nxtCells = mxGetCell(gHashedCells,MATLAB_TO_C(nextFrame));
	if (mp_nxtCells==NULL)
		return;

	if (mxGetNumberOfElements(mp_nxtCells)==0)
		return;

	double* updateCellCOM = mxGetPr(mxGetField(gCellHulls,MATLAB_TO_C(hullID),"centerOfMass"));
	if (updateCellCOM==NULL)
		mexErrMsgTxt("Cell does not have a center of mass");

	static double maxDisCOM = (double)mxGetScalar(mxGetField(gCONSTANTS,0,"dMaxCenterOfMass"));

	double comLimit = SQR(timeDif*maxDisCOM);
	nextCells.reserve(mxGetNumberOfElements(mp_nxtCells));
	int numNextCells = mxGetNumberOfElements(mp_nxtCells);

	// get a list of hulls to consider
	double* xComs = new double[numNextCells];
	double* yComs = new double[numNextCells];
	double* dists = new double[numNextCells];

	for (int i=0; i<numNextCells; ++i)
	{
		int cellId = (int)mxGetScalar(mxGetField(mp_nxtCells,i,"hullID"));
		double* nextCOM = mxGetPr(mxGetField(gCellHulls,MATLAB_TO_C(cellId),"centerOfMass"));
		xComs[i] = nextCOM[0];
		yComs[i] = nextCOM[1];
	}

	ispc::DistanceCalc(updateCellCOM[0],updateCellCOM[1],xComs,yComs,numNextCells,dists);

	for (int i=0; i<numNextCells; ++i)
	{
		int cellId = (int)mxGetScalar(mxGetField(mp_nxtCells,i,"hullID"));
		if (dists[i] <= comLimit)
			nextCells.push_back(cellId);
	}

	mxArray* ma_pixels = mxGetField(gCellHulls,MATLAB_TO_C(hullID),"indexPixels");
	double* mp_pixels = mxGetPr(ma_pixels);
	std::set<int> indexPixels;
	int numPixels = mxGetNumberOfElements(ma_pixels);
	double* xPixels = new double[numPixels];
	double* yPixels = new double[numPixels];

	for (int i=0; i<numPixels; ++i)
	{
		indexPixels.insert(mp_pixels[i]);
		ind2sub(mp_pixels[i],xPixels[i],yPixels[i]);
	}

	for (int i=0; i<nextCells.size(); ++i)
	{
		int numIntersect = 0;
		mxArray* ma_nextIndexPixels = mxGetField(gCellHulls,MATLAB_TO_C(nextCells[i]),"indexPixels");
		if (ma_nextIndexPixels==NULL)
			continue;

		// get number of intersecting pixels
		double* nextIndexPixels = mxGetPr(ma_nextIndexPixels);
		int numNextPixels = mxGetNumberOfElements(ma_nextIndexPixels);
		for (int j=0; j<numNextPixels; ++j)
			numIntersect += indexPixels.count(nextIndexPixels[j]);

		// If there is overlap, set the distance based on how many overlap
		if (numIntersect>0)
		{
			double dist = 1 - (double)numIntersect/std::min<int>(numNextPixels,numPixels);
			SetDistance(hullID,nextCells[i],dist,nextFrame-frameOfCell);
			continue;
		}

		// Cells don't overlap, set the distance based on the closest two pixels
		double ccMinDistSq = std::numeric_limits<double>::infinity();
		for (int j=0; j<numPixels; ++j)
		{
			double* xNextPixs = new double[numNextPixels];
			double* yNextPixs = new double[numNextPixels];
			double* distsNext = new double[numNextPixels];
			for (int k=0; k<numNextPixels; ++k)
			{
				ind2sub(nextIndexPixels[k],xNextPixs[k],yNextPixs[k]);
			}

			ispc::DistanceCalc(xPixels[j],yPixels[j],xNextPixs,yNextPixs,numNextPixels,distsNext);

			for (int k=0; k<numNextPixels; ++k)
			{
				if (distsNext[k]<ccMinDistSq)
					ccMinDistSq = distsNext[k];
			}

			delete[] xNextPixs;
			delete[] yNextPixs;
			delete[] distsNext;
		}

		double ccMaxDist = mxGetScalar(mxGetField(gCONSTANTS,0,"dMaxConnectComponent"));
		if (timeDif!=1)
			ccMaxDist *= 1.5;

		if (ccMinDistSq > SQR(ccMaxDist))
			continue;

		SetDistance(hullID,nextCells[i],sqrt(ccMinDistSq),nextFrame-frameOfCell);
	}

	delete[] xComs;
	delete[] yComs;
	delete[] dists;
	delete[] xPixels;
	delete[] yPixels;
}