# **LEVER**
### The Lineage Editing and Validation tool

LEVER is a collection of software tools for analyzing the development of proliferating (dividing) cells in time-lapes microscopy image sequences. LEVER includes algorithms for segmentation, tracking and lineaging. LEVER also includes a user interface that allows the segmentation, tracking and lineaging results to be *validated*, with any errors in the automated processing easily identified and corrected. 

#### Using LEVER for your imaging application

The key to analyzing time-lapse microscopy images of live proliferating cells is the *segmentation algorithm*. Given perfect segmentation and sufficient temporal resolution of imaging, the tracking and lineaging algorithms will never make a mistake. Sadly, (or happily, depending on your perspective) perfect segmentation will never exist. The entire LEVER architecture is designed to use temporal data from the tracking and contextual information on spatio-temporal population dynamics from the lineaging to improve the performance of the segmentation algorithm. 

The version of LEVER available here includes segmentation algorithms for adult and embryonic mouse neural stem cells imaged with phase contrast microscopy. There are as yet un-released segmentation algorithms for phase/brightfield and FUCCI images of human cancer cells and mouse T cells. There are also versions of LEVER that include 3-D visualization and segmentation for 5-D (3-D+time+channels) fluorescence microscopy including confocal, multi-photon and lattice light sheet. These algorithms will generally be released concurrent with the publication of the related manuscript(s). We are always interested in developing new collaborations - please contact acohen 'at' coe.drexel.edu if you are interested in working with us to develop a LEVER segmentation for your application.

Additional information on  LEVER can be found in the LEVER [wiki](https://git-bioimage.coe.drexel.edu/opensource/lever/wikis/home). This includes sections on using LEVER, and on extending the program with custom segmentation algorithms. 

#### Referencing LEVER
LEVER may be cited using:

* M. Winter, M. Liu, D. Monteleone, J. Melunis, U. Hershberg, S. K. Goderie, S. Temple, and A. R. Cohen, _Computational Image Analysis Reveals Intrinsic Multigenerational Differences Between Anterior and Posterior Cerebral Cortex Neural Progenitor Cells_, Stem Cell Reports, 2015. http://dx.doi.org/10.1016/j.stemcr.2015.08.002 [pubmed](http://www.ncbi.nlm.nih.gov/pubmed/26344906).

*  Winter et al., _Vertebrate neural stem cell segmentation, tracking and lineaging with validation and editing_, Nat Protocols, vol. 6, pp. 1942-1952, 2011. [pubmed](http://www.ncbi.nlm.nih.gov/pubmed/22094730).

 Additional LEVER publications include

* Mankowski, W. C., Winter, M. R., Wait, E., et al., _Segmentation of occluded hematopoietic stem cells from tracking_, Conf Proc IEEE Eng Med Biol Soc, vol. 2014, pp. 5510-3, 2014.[pubmed](http://www.ncbi.nlm.nih.gov/pubmed/25571242).

* Wait, E., Winter, M., Bjornsson, C., et al., _Visualization and correction of automated segmentation, tracking and lineaging from 5-D stem cell image sequences_, BMC Bioinformatics, vol. 15, 2014. [pubmed](http://www.ncbi.nlm.nih.gov/pubmed/25281197).

 LEVER uses an integrated tracking algorithm called Multitemporal Association Tracking (MAT). The algorithm, applied to tracking axonal organelle transport was originally published in the International Journal of Computational Biology and Drug Design. This is the best reference on MAT. A comparison of MAT and other particle tracking algorithms was subsequently published in Nature Methods. The same MAT algorithm, consisting of just a few hundred lines of C code has been applied to dozens of applications in cell and organelle tracking.

* Winter et al., _Axonal transport analysis using Multitemporal Association Tracking_, International Journal of Computational Biology and Drug Design, vol. 5, pp. 35-48, 2012. [pubmed](http://www.ncbi.nlm.nih.gov/pubmed/22436297).

* Chenouard et al., _Objective comparison of particle tracking methods_, Nat Methods, Jan 19 2014, [pubmed](http://www.ncbi.nlm.nih.gov/pubmed/24441936).

## Get The Source Code

##### Clone using [Git](https://git-scm.com) version control system
1. Open https://git-bioimage.coe.drexel.edu/opensource/lever
2. Use the url at the top of the page to clone the git repository

##### Download a zip archive
1. Open https://git-bioimage.coe.drexel.edu/opensource/lever/tree/master
2. Select Download zip option at the top of the page
3. Unzip into the desired directory

## Running LEVER
**An installer containing the compiled version of LEVER is available at** http://bioimage.coe.drexel.edu.

The installer is recommended for users that do not have access to MATLAB or do not need to develop new segmentation algorithms for use with LEVER. After installation LEVER can be run from the start menu.

### Running from source

1. Acquire the LEVER source through one of the above methods
2. Run MATLAB (2015b) and set the current directory to the Path-to-LEVER/src/matlab
3. Type 'LEVer' on the MATLAB command line to start the program
4. Choose 'Segment & Track' to segment new data or 'Existing' to open previously created LEVER data
5. If segmenting for the first time select an image that adheres to the required file name scheme (see below)
6. Select the segmentation type that corresponds to the cell type and microscope configuration

#### Image Naming Requirements
LEVER requires that images for cell segmentation and display adhere to the following format:

ExperimentName_c{channel number}_t{frame number}.tif

For example: Exp2010-01-24_c02_t0034.tif is a valid image file indicating the second channel and 34th frame from an experiment.

## Usage
General usage as well as specific interface documentation are linked below:
* [General editing commands](https://git-bioimage.coe.drexel.edu/opensource/lever/wikis/general-editing)
* [Tree specification interface](https://git-bioimage.coe.drexel.edu/opensource/lever/wikis/tree-editing)
* [Resegmentation interface](https://git-bioimage.coe.drexel.edu/opensource/lever/wikis/resegmentation-interface)

## Additional Information
Further information on LEVER is available on the bioimage/LEVER wiki at https://git-bioimage.coe.drexel.edu/opensource/lever/wikis/home

## License
Copyright (c) 2011-2016 Andrew Cohen

LEVer is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.
LEVer is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

A copy of the GNU GPL is available with LEVER (gnu gpl v3.txt). Otherwise see
<http://www.gnu.org/licenses/>.
