# **LEVER**
### The Lineage Editing and Validation tool

LEVER is a MATLAB tool for cell segmentation, tracking and lineaging. By default LEVER tries to identify neural stem cells in phase contrast images. However, the segmentation and tracking algorithms can be extended to identify other cell types using different image modalities. Additional information on extending LEVER can be found in the bioimage/LEVER [wiki](https://git-bioimage.coe.drexel.edu/opensource/lever/wikis/home).

#### Related Publications
LEVER has been applied to the analysis of thousands of neural progentior cells (NPC) across hundreds of clones. The NPC analysis results along with a discussion of our LEVER algorithms and CloneView web visualization tool was published in Stem Cell Reports.

M. Winter, M. Liu, D. Monteleone, J. Melunis, U. Hershberg, S. K. Goderie, S. Temple, and A. R. Cohen, _Computational Image Analysis Reveals Intrinsic Multigenerational Differences Between Anterior and Posterior Cerebral Cortex Neural Progenitor Cells_, Stem Cell Reports, 2015. http://dx.doi.org/10.1016/j.stemcr.2015.08.002

---
The original LEVER software protocol with usage instructions for analyzing proliferating cells was published in Nature Protocols.

Winter et al., _Vertebrate neural stem cell segmentation, tracking and lineaging with validation and editing_, Nature Protocols, vol. 6, pp. 1942-1952, 2011.

---
LEVER uses an integrated tracking algorithm termed Multitemporal Association Tracking (MAT). The algorithm, applied to microtubule transport tracking was originally published in the International Journal of Computational Biology and Drug Design. A comparison of MAT and other particle tracking algorithms was subsequently published in Nature Methods.

Chenouard et al., _Objective comparison of particle tracking methods_, Nature Methods, Jan 19 2014.

Winter et al., _Axonal transport analysis using Multitemporal Association Tracking_, International Journal of Computational Biology and Drug Design, vol. 5, pp. 35-48, 2012.

---
LEVER was developed at Drexel University's Bioimaging lab under the direction of Dr. Andrew Cohen. For more information check the lab homepage http://bioimage.coe.drexel.edu.

## Get The Source Code

##### Clone using Git version control system
1. Open https://git-bioimage.coe.drexel.edu/opensource/lever
2. Use the url at the top of the page to clone the git repository

##### Download a zip archive
1. Open https://git-bioimage.coe.drexel.edu/opensource/lever/tree/master
2. Select Download zip option at the top of the page
3. Unzip into the desired directory

## Running LEVER
**An installer containing the compiled version of LEVER is available at** http://bioimage.coe.drexel.edu.

The installer is recommended for users that do not have access to MATLAB or do not need to develop new segmentation algorithms for use with LEVER.

### Running from source

1. Acquire the LEVER source through one of the above methods
2. Run MATLAB (2012b) and set the current directory to the Path-to-LEVER/src/matlab
3. Choose 'Segment & Track' to segment new data or 'Existing' to open previously created LEVER data
4. If segmenting for the first time select an image that adheres to the required file name scheme (see below)
5. Select the segmentation type that corresponds to the cell type and microscope configuration

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
Copyright 2015 Andrew Cohen

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
