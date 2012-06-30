#include "GapStatistic.h"
#include <vnl/algo/vnl_svd.h>
#include <vnl/vnl_matrix.h>
#include <vnl/vnl_vector.h>
#include <vcl_iostream.h>

float DistanceSquared(coordinate vec1, coordinate vec2){
	return SQR(vec1.x-vec2.x) + SQR(vec1.y-vec2.y);
}

int Cluster(coordinate pixel, std::vector<coordinate>& means)
{
	double minDist = std::numeric_limits<double>::infinity();
	int minIdx = -1;
	for (int i=0; i<means.size(); ++i)
	{
		double dis = DistanceSquared(pixel,means[i]);
		if (dis<minDist)
		{
			minDist = dis;
			minIdx = i;
		}
	}

	return minIdx;
}

void KMeans(int k, const Hull& HULL, std::vector<int>& bestClasses) {
	const float THRESH = 1.2;

	int numPixels = HULL.pixels.size();
	float oldSumMeanSqrDist = std::numeric_limits<float>::infinity();
	std::vector<float> meanDistances;
	std::vector<coordinate> newMeans, oldMeans;
	std::vector<int> classCount,curClasses;

	meanDistances.resize(k);
	newMeans.resize(k);
	oldMeans.resize(k);
	classCount.resize(k);
	curClasses.resize(numPixels);
	bestClasses.clear();
	bestClasses.resize(numPixels);

	for (int j=0; j<numPixels; ++j)
	{
		bestClasses[j] = 0;
	}

	if (k<=1)
		return;

	for (int i=0; i<10; ++i)
	{
		for (int j=0; j<k; ++j)
		{
			int idx = rand()%numPixels;
			newMeans[j].x = oldMeans[j].x = (float)(HULL.pixels[idx][0]);
			newMeans[j].y = oldMeans[j].y = HULL.pixels[idx][1];
		}

		int itter = 0;
		bool belowThresh;
		do 
		{
			for(int j=0; j<numPixels; ++j){
				coordinate pix = {HULL.pixels[j][0],HULL.pixels[j][1]};
				curClasses[j] = Cluster(pix, newMeans);
			}

			for (int j=0; j<k; ++j)
			{
				newMeans[j].x = 0;
				newMeans[j].y = 0;
				classCount[j] = 0;
			}

			for (int j=0; j<numPixels; ++j)
			{
				newMeans[curClasses[j]].x += HULL.pixels[j][0];
				newMeans[curClasses[j]].y += HULL.pixels[j][1];
				++classCount[curClasses[j]];
			}

			for (int j=0; j<k; ++j)
			{
				newMeans[j].x /= classCount[j];
				newMeans[j].y /= classCount[j];
				meanDistances[j] = sqrt(DistanceSquared(oldMeans[j],newMeans[j]));
				oldMeans[j] = newMeans[j];
			}

			belowThresh = true;
			for (int j=0; j<k; ++j)
			{
				if (meanDistances[j]>THRESH)
				{
					belowThresh = false;
					break;
				}
			}

			++itter;
		} while (!belowThresh && itter<100);

		for (int j=0; j<k; ++j)
			classCount[j] = 0;

		for(int j=0; j<numPixels; ++j){
			coordinate pix = {HULL.pixels[j][0],HULL.pixels[j][1]};
			curClasses[j] = Cluster(pix, newMeans);
			++classCount[curClasses[j]];
		}

		for (int j=0; j<numPixels; ++j)
		{
			coordinate pix = {HULL.pixels[j][0],HULL.pixels[j][1]};
			meanDistances[curClasses[j]] = DistanceSquared(pix,newMeans[curClasses[j]]);
		}


		float sumMeanSqrDist = 0;
		for (int j=0; j<k; ++j)
		{
			meanDistances[j] /= classCount[j];
			sumMeanSqrDist += meanDistances[j];
		}

		if (sumMeanSqrDist<oldSumMeanSqrDist)
		{
			oldSumMeanSqrDist = sumMeanSqrDist;
			for (int i=0; i<numPixels; ++i)
				bestClasses[i] = curClasses[i];
		}	
	}
}

double gapWeight(int k, const Hull& HULL, std::vector<int>& idx)
{
	double weight = 0;
	std::vector<double> clusterWeights;
	std::vector<int> clusterCount;
	
	clusterWeights.resize(k);
	clusterCount.resize(k);

	for (int i=0; i<k; ++i)
	{
		clusterWeights[i] = 0;
		clusterCount[i] = 0;
	}

	for (int i=0; i<idx.size(); ++i)
	{
		for (int j=0; j<idx.size(); ++j)
		{
			if (idx[i]==idx[j])
			{
				coordinate pix1 = {HULL.pixels[j][0],HULL.pixels[j][1]};
				coordinate pix2 = {HULL.pixels[i][0],HULL.pixels[i][1]};
				clusterWeights[idx[i]] += DistanceSquared(pix1, pix2);
				++clusterCount[idx[i]];
			}
		}
	}

	for (int i=0; i<k; ++i)
	{
		weight += clusterWeights[i]/clusterCount[i];
	}

	return weight;
}

long double getWeight(int k, const Hull& HULL)
{
	std::vector<int> classes;
	KMeans(k, HULL, classes);
	
	return log(gapWeight(k,HULL,classes));
}

void makeData(const vnl_svd<double>& SVD, const int NUM_PIXELS, const double MAX[2], const double MIN[2], Hull& tempHull)
{
	vnl_matrix<double> randPix(NUM_PIXELS, 2);
	for (int i=0; i<randPix.rows(); ++i)
	{
		randPix(i,0) = ((double)rand() / RAND_MAX) * (MAX[0]-MIN[0]) + MIN[0];
		randPix(i,1) = ((double)rand() / RAND_MAX) * (MAX[1]-MIN[1]) + MIN[1];
	}

	randPix = randPix*SVD.V().transpose();

	tempHull.pixels.clear();
	tempHull.pixels.resize(randPix.rows());

	for (int i=0; i<randPix.rows(); ++i)
	{
		CharImageType::IndexType pixel;
		pixel[0] = randPix(i,0);
		pixel[1] = randPix(i,1);
		tempHull.pixels[i] = pixel;
	}
}

int getBest_K(const int K_MAX, std::vector<Hull>& hulls)
{
	// As Per Tibshirani
	// Gap(k) = (1/B)sum(log(W_kb)) - log(W_k)
	// sigma_k = sqrt[(1/B)sum{log(W_kb)-(1/B)sum(log(W_kb)}^2]
	// \^k = min(k) that Gap(K)>=Gap(k+1)-sigma_k+1(sqrt(1+1/B))
	// 
	int B = hulls.size()-1;
	long double sigma=0,gap=0,gap_1=0;
	int bestK = 0;

	for (int k_1=1; k_1<K_MAX; ++k_1, ++bestK)
	{
		sigma = 0;
		gap_1 = 0;

		long double observedWeight = getWeight(k_1,hulls[0]);
		long double summedReferenceWeight = 0; //(1/B)sum(log(W_kb)
		std::vector<long double> referenceWeights; //log(W_kb_j)
		referenceWeights.resize(B);

		for (int j=0; j<B; ++j)
		{
			summedReferenceWeight += referenceWeights[j] = getWeight(k_1,hulls[j+1]);
		}
		summedReferenceWeight /= B;

		gap_1 = summedReferenceWeight - observedWeight;

		for (int j=0; j<B; ++j)
			sigma += SQR(referenceWeights[j]-summedReferenceWeight);//sum{log(W_kb)-(1/B)sum(log(W_kb)}^2
		sigma /= B; //(1/B)sum{log(W_kb)-(1/B)sum(log(W_kb)}^2
		sigma = sqrt(sigma); //sqrt[(1/B)sum{log(W_kb)-(1/B)sum(log(W_kb)}^2]

		if (gap>=gap_1-sigma*(sqrt(1.0+1.0/B))) //Gap(K)>=Gap(k+1)-sigma_k+1(sqrt(1+1/B))
			break;

		gap = gap_1;
	}

	if (bestK>=K_MAX)
		return 1;

	return bestK;
}

void makeHulls(const Hull& ORG_HULL, std::vector<Hull>& newHulls, const std::vector<int>& CLASSES, const int K)
{
	newHulls.clear();
	newHulls.resize(K);

	for (int i=0; i<ORG_HULL.pixels.size(); ++i)
		newHulls[CLASSES[i]].pixels.push_back(ORG_HULL.pixels[i]);

	for (int i=0; i<K; ++i)
	{
		newHulls[i].centerOfMass[0] = 0.0;
		newHulls[i].centerOfMass[1] = 0.0;
		for (int j=0; j<newHulls[i].pixels.size(); ++j)
		{
			newHulls[i].centerOfMass[0] += newHulls[i].pixels[j][0];
			newHulls[i].centerOfMass[1] += newHulls[i].pixels[j][1];
		}
		newHulls[i].centerOfMass[0] /= (double)newHulls[i].pixels.size();
		newHulls[i].centerOfMass[1] /= (double)newHulls[i].pixels.size();
	}
}

void GapStatistic(LabelGeometryImageFilterType::LabelPointType centerOfMass,
	const LabelGeometryImageFilterType::LabelIndicesType& pixelCoordinates, std::vector<Hull>& hulls)
{
	const int B = 20; // B is the number of reference data from Tibshirani's paper
	const int K_MAX = 10;
	hulls.resize(1+B);
	Hull tempHull;
	tempHull.pixels.resize(pixelCoordinates.size());
	vnl_matrix<double> data(pixelCoordinates.size(), 2);

	for (int i=0; i<pixelCoordinates.size(); ++i)
	{
		CharImageType::IndexType pixel;
		data(i,0) = pixel[0] = pixelCoordinates[i][0];
		data(i,1) = pixel[1] = pixelCoordinates[i][1];
		tempHull.pixels[i] = pixel;
	}

	hulls[0] = tempHull;

	vnl_svd<double> svd(data);

	vnl_matrix<double> principleComps = data*svd.V();

	double max[2] = {principleComps.get_column(0).max_value(), principleComps.get_column(1).max_value()};
	double min[2] = {principleComps.get_column(0).min_value(), principleComps.get_column(1).min_value()};

	for (int i=0; i<B; ++i)
		makeData(svd, pixelCoordinates.size(), max, min, hulls[i+1]);

	int k = getBest_K(K_MAX,hulls);

	std::vector<int> classes;
	classes.resize(pixelCoordinates.size());

	KMeans(k,tempHull,classes);

	hulls.clear();

	makeHulls(tempHull,hulls,classes,k);
}