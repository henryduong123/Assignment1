#ifndef MEXCCDISTANCE_H
#define MEXCCDISTANCE_H

#include "mex.h"

#ifdef MEXMAT_EXPORTS
#define MEXMAT_LIB __declspec(dllexport)
#else
#define MEXMAT_LIB __declspec(dllimport)
#endif

#define C_IDX(x)		(x)
#define MATLAB_IDX(x)	(x)
#define C_TO_MATLAB(x)	((x)+1)
#define MATLAB_TO_C(x)	((x)-1)

#endif