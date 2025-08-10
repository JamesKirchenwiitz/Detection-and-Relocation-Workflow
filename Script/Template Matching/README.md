Listed in this readme is the order and explanation of all the scripts / files needed to properly run template matching for given events
NOTE: All of these are designed to be run directly from the command line in your localized linux machine

TEMPLATE MATCHING FLOW:

1. get.cat.py
- This script allows you to run a usgs rectangular or radius search for events based on varius parameters
- outputs a csv file written to what you specify, getcatpy.*input*.csv, used to feed template matching

2. hpc.detect.3sta.local.csh
- Template matching script
- Running from the command line syntax: 
- If getcatpy file is named getcatpy.2023feb09.csv, input is: hpc.detect.3sta.local.csh 2023feb09
- Outputs matches as files

3. combine.lcurve.bytemp.csh *input*
- Combines all the matches into one master file
- Using feb09 as file input still, output would be: 2023feb09.combine.bytemp.txt

4. plot.wf.mag.match.csh
- Plots templates and matches with magnitude and cross correlation values on the right of waveforms, with a magnitude over time plot
