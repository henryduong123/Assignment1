//******************************************************
//
//    This file is part of LEVer.exe
//    (C) 2011 Andrew Cohen, Eric Wait and Mark Winter
//
//******************************************************

#include <vector>
#include <list>
#include <map>

typedef std::numeric_limits<double> dbltype;

class CSourcePath
{
public:
	CSourcePath()
	{
		trackletID = -1;
		cost = dbltype::infinity();
	}

	void PushPoint(int t, int idx)
	{
		frame.push_back(t);
		index.push_back(idx);
	}

	void PopPoint()
	{
		if ( frame.size() <= 1 )
			return;

		frame.pop_back();
		index.pop_back();
	}

public:

	int trackletID;
	double cost;

	std::vector<int> frame;
	std::vector<int> index;

};

int GetGlobalIdx(int t, int idx);
int GetLocalIdx(int globalIdx);
void BuildBestPaths(std::vector<CSourcePath*>* inEdges, CSourcePath** outEdges, int t, int occlLookcback = 0);
