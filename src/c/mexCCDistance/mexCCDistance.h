#ifndef MEXCCDISTANCE_H
#define MEXCCDISTANCE_H

#include "mex.h"
#include <vector>
#include <map>
#include <set>

#ifdef MEXMAT_EXPORTS
#define MEXMAT_LIB __declspec(dllexport)
#else
#define MEXMAT_LIB __declspec(dllimport)
#endif

#define C_IDX(x)		(x)
#define MATLAB_IDX(x)	(x)
#define C_TO_MATLAB(x)	((x)+1)
#define MATLAB_TO_C(x)	((x)-1)

#define ARRAY_SIZE(x) (sizeof(x) / sizeof((x)[0]))
#define SQR(x) ((x)*(x))

struct coordinate 
{
	int x;
	int y;
};

struct Hull
{
	int time;
	double centerOfMass[2];
	std::set<int> pixelindices;
	double* xPixels;
	double* yPixels;
	bool deleted;
};

struct updateData 
{
	int cellID;
	int frameOfCell;
	int nextFrame;
};

extern const mxArray* gCellHulls;
extern const mxArray* gConnectedDist;
extern const mxArray* gHashedCells;
extern const mxArray* gCONSTANTS;
extern std::vector<std::map<int,double>> gConnectedDistLcl;
extern std::vector<Hull> gCellHullsLcl;
extern std::vector<std::set<int>> gHashedCellsLcl;
extern double gmaxDisCOM;
extern double ccMaxDist;

#endif