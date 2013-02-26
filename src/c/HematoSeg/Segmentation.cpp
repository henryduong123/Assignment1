#include "Segmentation.h"
#include "itkTIFFImageIO.h"

#include "GapStatistic.h"

//#pragma optimize("",off)
DWORD WINAPI segmentation(LPVOID lpParam)
{
	clock_t startTime = clock();
	segData* parameters = (segData*)lpParam;

	CharImageFileReaderType::Pointer		charReader =		CharImageFileReaderType::New();
	CharImageFileWriterType::Pointer		charWriter =		CharImageFileWriterType::New();
	ShortImageFileWriterType::Pointer		shortWriter =		ShortImageFileWriterType::New();

	itk::TIFFImageIO::Pointer				imageIO =			itk::TIFFImageIO::New();

	ScalarImageToHistogramGeneratorType::Pointer histogramGeneratorOrg = ScalarImageToHistogramGeneratorType::New();
	ScalarImageToHistogramGeneratorType::Pointer histogramGeneratorIg = ScalarImageToHistogramGeneratorType::New();
	OtsuThresholdCalculatorType::Pointer	thresholdCalculatorOrg = OtsuThresholdCalculatorType::New();
	OtsuThresholdCalculatorType::Pointer	thresholdCalculatorIg = OtsuThresholdCalculatorType::New();
	ThresholdFilterType::Pointer			thresholdFilterOrg =	ThresholdFilterType::New();
	ThresholdFilterType::Pointer			thresholdFilterIg =	ThresholdFilterType::New();
	
	ErodeFilterType::Pointer				binaryErode =		ErodeFilterType::New();
	DilateFilterType::Pointer				binaryDilate =		DilateFilterType::New();
	ErodeFilterType::Pointer				binaryErode2 =		ErodeFilterType::New();
	DilateFilterType::Pointer				binaryDilate2 =		DilateFilterType::New();
	GrayscaleDilateFilterType::Pointer		grayDilate =		GrayscaleDilateFilterType::New();
	GrayscaleErodeFilterType::Pointer		grayErode =			GrayscaleErodeFilterType::New();
	SubtractImageFilterType::Pointer		subtractor =		SubtractImageFilterType::New();
	BinaryNotImageFilterType::Pointer		binaryNot =			BinaryNotImageFilterType::New();
	AndImageFilterType::Pointer				binaryAnd =			AndImageFilterType::New();
	BinaryFillholeImageFilterType::Pointer  binaryHoleFillerOrg =  BinaryFillholeImageFilterType::New();
	BinaryFillholeImageFilterType::Pointer  binaryHoleFillerIg =  BinaryFillholeImageFilterType::New();
	ConnectedComponentFilterType::Pointer	labelerOrg =			ConnectedComponentFilterType::New();
	ConnectedComponentFilterType::Pointer	labelerIg =			ConnectedComponentFilterType::New();
	LabelGeometryImageFilterType::Pointer	labelGeometryImageFilterOrg = LabelGeometryImageFilterType::New();
	LabelGeometryImageFilterType::Pointer	labelGeometryImageFilterIg = LabelGeometryImageFilterType::New();
	
	StructuringElementType		structuringElement1;
	StructuringElementType		structuringElement2;

	// setup charReader to read from TIFs
	charReader->SetImageIO(imageIO);
	charReader->SetFileName(parameters->imageFile);
	charReader->Update();

	// compute a histogram of the image
	histogramGeneratorOrg->SetNumberOfBins(256);
	histogramGeneratorOrg->SetInput(charReader->GetOutput());
	histogramGeneratorOrg->Compute();

	// maximize between-class variance in the histogram
	thresholdCalculatorOrg->SetInput(histogramGeneratorOrg->GetOutput());
	thresholdCalculatorOrg->Update();

	itk::SimpleDataObjectDecorator<double>* threshOrg = thresholdCalculatorOrg->GetOutput();
	float thresholdOrg = threshOrg->Get();

	thresholdOrg *= parameters->imageAlpha;

	thresholdFilterOrg->SetLowerThreshold(thresholdOrg);
	thresholdFilterOrg->SetOutsideValue(0);
	thresholdFilterOrg->SetInsideValue(-1);
	thresholdFilterOrg->SetUpperThreshold(255);
	thresholdFilterOrg->SetInput(charReader->GetOutput());

	// this sets up the image dilation
	structuringElement1.SetRadius(2);
	structuringElement1.CreateStructuringElement();

	binaryErode->SetKernel(structuringElement1);
	binaryErode->SetInput(thresholdFilterOrg->GetOutput());

	binaryDilate->SetKernel(structuringElement1);
	binaryDilate->SetInput(binaryErode->GetOutput());

	binaryDilate2->SetKernel(structuringElement1);
	binaryDilate2->SetInput(binaryDilate->GetOutput());

	binaryErode2->SetKernel(structuringElement1);
	binaryErode2->SetInput(binaryDilate2->GetOutput());

	binaryHoleFillerOrg->SetInput(binaryErode2->GetOutput());
	binaryHoleFillerOrg->SetFullyConnected(true);

	labelerOrg->SetInput(binaryHoleFillerOrg->GetOutput());

	labelGeometryImageFilterOrg->CalculatePixelIndicesOn();
	labelGeometryImageFilterOrg->SetInput(labelerOrg->GetOutput());

	structuringElement2.SetRadius(2);
	structuringElement2.CreateStructuringElement();

	grayDilate->SetKernel(structuringElement2);
	grayDilate->SetInput(charReader->GetOutput());
	grayDilate->Update();
	grayErode->SetKernel(structuringElement2);
	grayErode->SetInput(charReader->GetOutput());
	grayErode->Update();

	subtractor->SetInput1(grayDilate->GetOutput());
	subtractor->SetInput2(grayErode->GetOutput());
	subtractor->Update();

	histogramGeneratorIg->SetNumberOfBins(256);
	histogramGeneratorIg->SetInput(subtractor->GetOutput());
	histogramGeneratorIg->Compute();

	thresholdCalculatorIg->SetInput(histogramGeneratorIg->GetOutput());
	thresholdCalculatorIg->Update();

	itk::SimpleDataObjectDecorator<double>* threshIg = thresholdCalculatorIg->GetOutput();
	float thresholdIg = threshIg->Get();

	thresholdIg *= parameters->imageAlpha;

	thresholdFilterIg->SetLowerThreshold(thresholdIg);
	thresholdFilterIg->SetOutsideValue(0);
	thresholdFilterIg->SetInsideValue(-1);
	thresholdFilterIg->SetUpperThreshold(255);
	thresholdFilterIg->SetInput(subtractor->GetOutput());

	binaryNot->SetInput(thresholdFilterIg->GetOutput());
	binaryAnd->SetInput1(binaryNot->GetOutput());
	binaryAnd->SetInput2(binaryHoleFillerOrg->GetOutput());

	binaryHoleFillerIg->SetInput(binaryAnd->GetOutput());
	binaryHoleFillerIg->SetFullyConnected(false);

	labelerIg->SetInput(binaryHoleFillerIg->GetOutput());

	labelGeometryImageFilterIg->CalculatePixelIndicesOn();
	labelGeometryImageFilterIg->SetInput(labelerIg->GetOutput());

	labelGeometryImageFilterOrg->Update();
	labelGeometryImageFilterIg->Update();

	//charWriter->SetFileName("ig.tiff");
	//charWriter->SetImageIO(imageIO);
	//charWriter->SetInput(thresholdFilterIg->GetOutput());
	//charWriter->Update();

	//charWriter->SetFileName("fore.tiff");
	//charWriter->SetImageIO(imageIO);
	//charWriter->SetInput(binaryHoleFillerOrg->GetOutput());
	//charWriter->Update();

	std::vector<ShortPixelType> labelsOrg = labelGeometryImageFilterOrg->GetLabels();
	std::vector<ShortPixelType> labelsIg = labelGeometryImageFilterIg->GetLabels();

	CharImageType::SizeType size = charReader->GetOutput()->GetLargestPossibleRegion().GetSize();

	ShortImageType::Pointer labelerOrgImg = labelerOrg->GetOutput();

	std::vector<std::vector<coordinate>> means;
	means.resize(labelsOrg.size());

	for (int i=1; i<labelsIg.size(); ++i)
	{
		std::vector<coordinate> tempMeans;
		LabelGeometryImageFilterType::LabelPointType centerOfMass = 
			labelGeometryImageFilterIg->GetCentroid(labelsIg[i]);

		LabelGeometryImageFilterType::LabelIndicesType pixelCoordinates= 
			labelGeometryImageFilterIg->GetPixelIndices(labelsIg[i]);
		std::vector<Hull> tempHulls;
		double vol = labelGeometryImageFilterIg->GetVolume(labelsIg[i]);
		if (vol<parameters->minSize*.4)
			continue;

		int kMax = floor((double)vol/(parameters->minSize*.6));

		GapStatistic(centerOfMass,pixelCoordinates,kMax+1,tempMeans);

		for (int j=0; j<tempMeans.size(); ++j)
		{
			ShortImageType::IndexType point;
			point[0] = (unsigned short)tempMeans[j].x;
			point[1] = (unsigned short)tempMeans[j].y;

			unsigned short meanLabel = labelerOrgImg->GetPixel(point);
			means[meanLabel].push_back(tempMeans[j]);
		}
		//printf("labelsIg=%d\n",i);
	}

	std::vector<int> labelsToUse;

	for (int i=0; i<labelsOrg.size(); ++i)
	{
		double eccentricity = labelGeometryImageFilterOrg->GetEccentricity(i);
		double minorAxes = labelGeometryImageFilterOrg->GetMinorAxisLength(i);
		int vol = labelGeometryImageFilterOrg->GetVolume(i);
		if (vol<parameters->minSize) continue;
		if (eccentricity>parameters->eccentricity && minorAxes<sqrt((double)parameters->minSize))
			continue;
		labelsToUse.push_back(i);
	}

	char buffer[255];
	//int idx = parameters->imageFile.find_last_of("\\");

	std::vector<Hull> hulls;
	hulls.reserve(labelsToUse.size()*1.4);
	for (int i=1; i<labelsToUse.size(); ++i)
	{
		LabelGeometryImageFilterType::LabelPointType centerOfMass = 
			labelGeometryImageFilterOrg->GetCentroid(labelsToUse[i]);

		LabelGeometryImageFilterType::LabelIndicesType pixelCoordinates= 
			labelGeometryImageFilterOrg->GetPixelIndices(labelsToUse[i]);

		Hull hull;
		hull.centerOfMass[0] = centerOfMass[0];
		hull.centerOfMass[1] = centerOfMass[1];
		hull.pixels.resize(pixelCoordinates.size());

		for (int j=0; j<pixelCoordinates.size(); ++j)
		{
			hull.pixels[j][0] = pixelCoordinates[j][0];
			hull.pixels[j][1] = pixelCoordinates[j][1];
		}

		std::vector<Hull> tempHulls;
		SetClusters(hull,means[labelsToUse[i]],tempHulls);
		hulls.insert(hulls.end(),tempHulls.begin(),tempHulls.end());
		int sz=hulls.size();
	}

	std::string outputText = "";
	sprintf_s(buffer,"%d\n",hulls.size());
	outputText += buffer; // Number of hulls in the document
	for (int i=0; i<hulls.size(); ++i)
	{
		sprintf_s(buffer,"(%f,%f)\n",hulls[i].centerOfMass[0],hulls[i].centerOfMass[1]);
		outputText += buffer; // Center of Mass

		sprintf_s(buffer,"%d\n",hulls[i].pixels.size());
		outputText += buffer; // Number of pixelCoordiantes to follow
		for (int j=0; j<hulls[i].pixels.size(); ++j)
		{
			sprintf_s(buffer,"%d,",hulls[i].pixels[j][1]+hulls[i].pixels[j][0]*size[1] +1);
			outputText += buffer;
		}

		outputText += "\n";
	}

	double dif = ((double)clock() - (double)startTime) / CLOCKS_PER_SEC;

	sprintf_s(buffer,"\nseconds to segment: %f\n",dif);
	outputText += buffer;

	FILE* file = fopen(parameters->outFile.c_str(),"w");
	fprintf_s(file,"%s",outputText.c_str());
	fclose(file);
	printf("wrote %s\n",parameters->outFile.c_str());

	return 0;
}
