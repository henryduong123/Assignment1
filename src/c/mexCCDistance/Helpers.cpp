#include "Helpers.h"
#include "mexCCDistance.h"

void ind2sub(int ind, double& x, double& y)
{
	const static double* imageSize = mxGetPr(mxGetField(gCONSTANTS,0,"imageSize"));
	coordinate temp;
	y = MATLAB_TO_C(ind) % (int)imageSize[0];
	x = MATLAB_TO_C(ind) / (int)imageSize[0];
}

void SetDistance(int updateCell, int nextCell, double dist, int updateDir)
{
	if (updateDir<0)
	{
		int tmp = updateCell;
		updateCell = nextCell;
		nextCell = tmp;
	}

	if (gConnectedDistLcl[MATLAB_TO_C(updateCell)].count(nextCell)>0)
		gConnectedDistLcl[MATLAB_TO_C(updateCell)].at(nextCell) = dist;
	else
	{
		std::pair<int,double> cost(nextCell,dist);
		gConnectedDistLcl[MATLAB_TO_C(updateCell)].insert(cost);
	}
}