#ifndef GAPSTATISTIC_H
#define GAPSTATISTIC_H

#include "Segmentation.h"

#define SQR(x) ((x)*(x))

void GapStatistic(LabelGeometryImageFilterType::LabelPointType centerOfMass,
	const LabelGeometryImageFilterType::LabelIndicesType& pixelCoordinates,
	const int K_MAX, std::vector<coordinate>& means);

void SetClusters(const Hull& HULL, std::vector<coordinate>& means, std::vector<Hull>& newHulls);

#endif