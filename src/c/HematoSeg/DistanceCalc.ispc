export void DistanceCalc(uniform double x, uniform double y, uniform double x2[],
	uniform double y2[], uniform int count, uniform double dists[])
{
	foreach(index=0 ... count)
	{
		dists[index] = (x-x2[index])*(x-x2[index]) + (y-y2[index])*(y-y2[index]);
	}
}