#ifndef GAPSTATISTIC_H
#define GAPSTATISTIC_H

#include "Segmentation.h"

#define SQR(x) ((x)*(x))

void GapStatistic(LabelGeometryImageFilterType::LabelPointType centerOfMass,
	const LabelGeometryImageFilterType::LabelIndicesType& pixelCoordinates, std::vector<Hull>& hulls);

#endif