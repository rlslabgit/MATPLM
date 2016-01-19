# MATPLM1.2 Directions for use:

### EDF-Matlab struct conversion
(See TextFileFormats.pdf for explanation of how to format files and
directories to work with Allen_Ebm_2_Matlab batch EDF and RemLogic converter)

1.  Create a directory to store the edf and text files for a patient
    with the filename: AidRLS, G####_V#N# - 6_21_2013. (Date is optional)

2.  Export the following from RemLogic (or create manually) into the
    folder created above:
    * **Traces.edf (required)**
    * **G#####_V#N# AidRLS-Events SleepStage (required)**
    * G#####_V#N# AidRLS-Events Arousal (optional)
    * G#####_V#N# AidRLS-Events Apnea (optional)
     
3.  In `MATPLM1.2/EDF Conversion/Allen_Ebm_2_Matlab.m`, change the
    variable `ProtocolDIR` to the directory containing the patient folder
    with the edf and appropriate text files. Also, change `modDateAfter` to
    the date before the last unconverted patient: the program will convert
    all folders modified after this date.

4.  Run `Allen_Ebm_2_Matlab.m`. Each of the folders will now contain a
    MATLAB file with information collected from the edf file and text files.

### EDF-Matlab (w/out event text files)
If the only data you have is the edf file, run the function:
`EDF_read_jhmi_rev_101.m` in the EDF conversion folder. The function takes
the full path of the edf file to be converted. If you produce the MATLAB
file this way, there are several shortcomings of the program, owing especially
to the absense of the Sleep Staging information and EDFStart2Hypno.

    1. No sleep staging info, i.e. no distincion between PLMS and PLMW
    2. No defined start and stop times. This may create problems because
       EMG often contains sections of calibration or other unwanted data.
       Program could possibly fail on certain records, not sure yet.
    3. No apnea and arousal data.

In general, the program will score ALL PLM, and will not be able to distinguish
between sleep stages, breathing-disordered events and recording calibration
artifacts.
***************************************************************************
### Scoring of PLM
That was the difficult part, since it is particular to
a certain style. Once you have the Matlab files with EMG
and staging (at least), the program is much easier to 
make sense of.

Now, you can import the matlab file you want and run the function:
`minifullRunComboScript(StructName)`, where StructName is the struct you
imported. It is recommended to run the code with all the bracketed outputs,
otherwise the program will display a graph of each leg, with LM marked for
each leg and PLM superimposed on both, as well as a histogram of the IMIs 
in log space. In addition, numerical outputs will be written to a text file
with this patient's name in the subfolder: Patient Data Files.

`PlotStuff` can be used to...plot stuff. You can choose two LM arrays and
one PLM, and if the HypnogramStart time is available, the plot will include
time of night from the recording.

Some important notes
* PlotStuff: if no Hypnogram is found the graph will not show any PLM,
since it only shows those in sleep!
* You *must* create a directory within MATPLM called `Patient Data Files` for
    the program to store the text file outputs. It will fail if this directory is
    not present (I'll fix this eventually)


