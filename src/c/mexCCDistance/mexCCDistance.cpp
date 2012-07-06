#include <Windows.h>

#include <vector>
#include <map>
#include <set>

#include "mexCCDistance.h"
#include "UpdateDistances.h"
#include "UpdateDistancesThreaded.h"
#include "Helpers.h"

#define WINDOW_SIZE (2)

const mxArray* gCellHulls;
const mxArray* gConnectedDist;
const mxArray* gHashedCells;
const mxArray* gCONSTANTS;
std::vector<std::map<int,double>> gConnectedDistLcl;
std::vector<Hull> gCellHullsLcl;
std::vector<std::set<int>> gHashedCellsLcl;
double gmaxDisCOM;
double ccMaxDist;

//#pragma optimize ("",off)
void threadLoop(int j, int numHulls, double* updateCells)
{
	SYSTEM_INFO sysinfo;
	GetSystemInfo( &sysinfo );
	int numCPU = sysinfo.dwNumberOfProcessors;

	updateData* pArguments = new updateData[numCPU];
	DWORD*   dwThreadIdArray = new DWORD[numCPU];
	HANDLE*  hThreadArray = new HANDLE[numCPU]; 
	int nextEmptyThread = 0;
	bool filling = TRUE;
	char buffer[255];

	for (int i=0; i<numCPU; ++i)
		hThreadArray[i] = NULL;

	for (int i=0; i<numHulls; ++i)
	{
		if (gCellHullsLcl[i].deleted)
			continue;

		pArguments[nextEmptyThread].cellID = updateCells[i];
		pArguments[nextEmptyThread].frameOfCell = gCellHullsLcl[MATLAB_TO_C(updateCells[i])].time;
		pArguments[nextEmptyThread].nextFrame = gCellHullsLcl[MATLAB_TO_C(updateCells[i])].time+j;

		hThreadArray[nextEmptyThread] = CreateThread(
			NULL,
			0,
			UpdateDistancesThreaded,
			(LPVOID)(&pArguments[nextEmptyThread]),
			FALSE,
			&dwThreadIdArray[nextEmptyThread]);

		if( hThreadArray[nextEmptyThread] == NULL )
		{
			char buffer[255];
			sprintf_s(buffer,"CreateThread error: %d\n", GetLastError());
			mexErrMsgTxt(buffer);
			return;
		}

		++nextEmptyThread;
		if (nextEmptyThread==numCPU)
			filling = false;

		if (i==numHulls-1)
			break;

		if(!filling)
		{
			DWORD doneThread = WaitForMultipleObjects(
				numCPU,
				hThreadArray,
				FALSE,
				INFINITE);

			DWORD ind = doneThread - WAIT_OBJECT_0;
			nextEmptyThread = ind;
			if (nextEmptyThread>=numCPU)
			{
				char* message;
				FormatMessageA(
					FORMAT_MESSAGE_ALLOCATE_BUFFER|FORMAT_MESSAGE_FROM_SYSTEM,
					NULL,
					GetLastError(),
					0,
					(LPSTR)&message,
					10,
					NULL);
				mexErrMsgTxt(message);
			}
			CloseHandle(hThreadArray[ind]);
			hThreadArray[ind] = NULL;
		}
	}

	if (filling)
	{
		WaitForMultipleObjects(
			nextEmptyThread,
			hThreadArray,
			TRUE,
			INFINITE);
	}else
	{
		WaitForMultipleObjects(
			numCPU,
			hThreadArray,
			TRUE,
			INFINITE);
	}

	for (int i=0; i<numCPU; ++i)
		if (hThreadArray[i]!=NULL)
			CloseHandle(hThreadArray[i]);

	delete[] pArguments;
	delete[] dwThreadIdArray;
	delete[]  hThreadArray;
}

//#pragma optimize ("",off)
void mexFunction(int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[])
{
	if (nrhs != 2)
		mexErrMsgTxt("Input argument count is wrong");
	if (nlhs !=0)
		mexErrMsgTxt("No output argument available");

	gCellHulls = mexGetVariablePtr("global", "CellHulls");
	gConnectedDist = mexGetVariablePtr("global", "ConnectedDist");
	gHashedCells = mexGetVariablePtr("global", "HashedCells");
	gCONSTANTS = mexGetVariablePtr("global", "CONSTANTS");

	int mat_maxId = mxGetNumberOfElements(gConnectedDist);
	ccMaxDist = mxGetScalar(mxGetField(gCONSTANTS,0,"dMaxConnectComponent"));

	double* updateCells = mxGetPr(prhs[0]);
	for (int i=0; i<mxGetNumberOfElements(prhs[0]); ++i)
	{
		mat_maxId = std::max<int>(mat_maxId,(int)updateCells[i]);
	}

	if (mat_maxId==0)
		mexErrMsgTxt("Invalid update cell list");

	gConnectedDistLcl.clear();
	gConnectedDistLcl.resize(mat_maxId);

	// if updating backwards (***NOT THREAD SAFE***)
	if ((bool)mxGetScalar(prhs[1]))
	{
		// copy data locally to be manipulated
		for (int i=0; i<mxGetNumberOfElements(gConnectedDist); ++i)
		{
			mxArray* cell = mxGetCell(gConnectedDist,i);
			if(cell==NULL) continue;
			double* data = mxGetPr(cell);

			for (int c_j=0; c_j<mxGetM(cell); ++c_j)
			{
				mwIndex idx[2] = {c_j,0};
				int mat_cellID = (int)data[mxCalcSingleSubscript(cell,2,idx)];

				idx[1] = 1;
				double dist = data[mxCalcSingleSubscript(cell,2,idx)];

				std::pair<int,double> vals(mat_cellID,dist);
				gConnectedDistLcl[i].insert(vals);
			}
		}

		for (int i=0; i<mxGetNumberOfElements(prhs[0]); ++i)
		{
			bool del = (bool)mxGetScalar(mxGetField(gCellHulls,MATLAB_TO_C(updateCells[i]),"deleted"));
			if (del) continue;

			gConnectedDistLcl[MATLAB_TO_C(updateCells[i])].clear();
			int time = (int)mxGetScalar(mxGetField(gCellHulls,MATLAB_TO_C(updateCells[i]),"time"));

			UpdateDistances(updateCells[i],time,time+1);
			UpdateDistances(updateCells[i],time,time+2);
			UpdateDistances(updateCells[i],time,time-1);
			UpdateDistances(updateCells[i],time,time-2);
		}
	}else
	{
		char buffer[255];
		gCellHullsLcl.resize(mxGetNumberOfElements(gCellHulls));

		for (int i=0; i<gCellHullsLcl.size(); ++i)
		{
			mxArray* time = mxGetField(gCellHulls,i,"time");
			if (time==NULL)
			{
				sprintf_s(buffer,"Time is empty for cell %d",i);
				mexErrMsgTxt(buffer);
			}
			gCellHullsLcl[i].time = (double)mxGetScalar(time);

			mxArray* bDeleted = mxGetField(gCellHulls,i,"deleted");
			if (bDeleted==NULL)
			{
				sprintf_s(buffer,"Deleted is empty for cell %d",i);
				mexErrMsgTxt(buffer);
			}
			gCellHullsLcl[i].deleted = (bool)mxGetScalar(bDeleted);

			mxArray* com = mxGetField(gCellHulls,i,"centerOfMass");
			if (com==NULL)
			{
				sprintf_s(buffer, "Bad COM of cell %d",i);
				mexErrMsgTxt(buffer);
			}
			double* comData = mxGetPr(com);
			gCellHullsLcl[i].centerOfMass[0] = comData[0];
			gCellHullsLcl[i].centerOfMass[1] = comData[1];

			mxArray* pixelIndices = mxGetField(gCellHulls,i,"indexPixels");
			if (pixelIndices==NULL)
			{
				sprintf_s(buffer,"Bad pointer to indexPixels of hull %d", i);
				mexErrMsgTxt(buffer);
			}
			int sz = mxGetNumberOfElements(pixelIndices);
			double* pixelIndicesData = mxGetPr(pixelIndices);
			gCellHullsLcl[i].xPixels = new double[sz];
			gCellHullsLcl[i].yPixels = new double[sz];
			for (int j=0; j<sz; ++j)
			{
				gCellHullsLcl[i].pixelindices.insert(pixelIndicesData[j]);
				ind2sub(pixelIndicesData[j],gCellHullsLcl[i].xPixels[j], gCellHullsLcl[i].yPixels[j]);
			}
		}

		gHashedCellsLcl.resize(mxGetNumberOfElements(gHashedCells));
		for (int i=0; i<gHashedCellsLcl.size(); ++i)
		{
			mxArray* hullList = mxGetCell(gHashedCells,i);
			if (hullList==NULL)
				continue;
			for (int j=0; j<mxGetNumberOfElements(hullList); ++j)
			{
				mxArray* hullsListData = mxGetField(hullList,j,"hullID");
				if (hullsListData==NULL)
				{
					sprintf_s(buffer,"bad hulls in %d time %d", i, j);
					mexErrMsgTxt(buffer);
				}
				gHashedCellsLcl[i].insert(mxGetScalar(hullsListData));
			}				
		}

		gmaxDisCOM = (double)mxGetScalar(mxGetField(gCONSTANTS,0,"dMaxCenterOfMass"));

		int numHulls= mxGetNumberOfElements(prhs[0]);

		threadLoop(1,numHulls,updateCells);
		threadLoop(2,numHulls,updateCells);

		for (int i=0; i<gCellHullsLcl.size(); ++i)
		{
			delete[] gCellHullsLcl[i].xPixels;
			delete[] gCellHullsLcl[i].yPixels;
		}
	}

	mxArray* ccDistOut = mxCreateCellMatrix(1,mxGetNumberOfElements(gCellHulls));
	
	for (int i=0; i<gConnectedDistLcl.size(); ++i)
	{
		int numDists = gConnectedDistLcl[i].size();
		mxArray* curDists = mxCreateDoubleMatrix(numDists,2,mxREAL);
		mxSetCell(ccDistOut,i,curDists);

		double* data = mxGetPr(curDists);
		int j=0;
		for (std::map<int,double>::iterator it=gConnectedDistLcl[i].begin(); it!=gConnectedDistLcl[i].end(); ++it, ++j)
		{
			data[j] = it->first;
			data[j+numDists] = it->second;
		}
	}

	mexPutVariable("global","ConnectedDist",ccDistOut);
}