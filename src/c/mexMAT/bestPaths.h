
// Double limits convenience definition
typedef std::numeric_limits<double> DoubleLims;

class CSourcePath
{
public:
	CSourcePath()
	{
		sourceIdx = -1;
		cost = DoubleLims::infinity();
	}

	void pushPoint(int newIdx)
	{
		path.push_back(newIdx);
	}

	void popPoint()
	{
		if ( path.size() <= 1 )
			return;

		path.pop_back();
	}

	void setAsHistory()
	{
		sourceIdx = path.size();
	}

	void reserve(int size)
	{
		path.reserve(size);
	}

	void clear()
	{
		sourceIdx = -1;
		cost = DoubleLims::infinity();
		path.clear();
	}

public:

	int sourceIdx;
	double cost;

	std::vector<int> path;
};

void buildBestPaths(int t, int numTracks);