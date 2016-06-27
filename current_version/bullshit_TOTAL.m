addpath(['C:\Users\Administrator\Documents\GitHub\'...
    'MATPLM (rlslabgit)\EDF Conversion']);

EDF = convert_1sub_rev1('D:\Glutamate Study\');
[plm_outputs, lEMG, rEMG] = matplm_new_main_rev1(EDF);