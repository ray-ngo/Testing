# -*- coding: utf-8 -*-
"""
Created on Fri Feb  5 16:28:47 2021

@author: binny.paul
Revised Andrew Rohne 7/3/2024 to check that mapping doesn't exist before adding it
"""
import os, sys
from shutil import copyfile
import openmatrix as omx
import numpy as np

## Define User Inputs
#ProjectDir = r'E:/Projects/Clients/MWCOG'
print ("Converting cube to omx")

WorkingDir = sys.argv[3]
CubeSkimDir = os.path.join(WorkingDir, 'outputs\skims')
OutputDir = os.path.join(WorkingDir, CubeSkimDir, 'OMX_Skims')
cube_to_emme_exe = os.path.abspath(os.path.join(WorkingDir, '..', 'source\software\\application\cube_to_omx\cube2omx.exe'))

tskm_prefix = sys.argv[1]
time_periods = ['AM','OP','MD', 'PM', 'NT']
access_modes = ['WK','DR','KR']
egress_modes = ['WK','DR','KR']
transit_mode = ['AB','MR','CR','BM','ALL_TRANSIT']

hskm_prefix = sys.argv[2]
hwy_modes = ['sov','hov2','hov3']

# Transit skim names
TSKM_names = [tskm_prefix + "_" + t + "_" + acc + "_" + tm + "_" + egr + '.SKM'
             for t in time_periods for acc in access_modes for tm in transit_mode for egr in egress_modes]


TSKM_OMX_names = [tskm_prefix + "_" + t + "_" + acc + "_" + tm + "_" + egr + '.omx'
             for t in time_periods for acc in access_modes for tm in transit_mode for egr in egress_modes]


# Highway skim names
HSKM_names = [hskm_prefix + "_" + t + "_" + hm + '.skm' for t in time_periods for hm in hwy_modes]
HSKM_names.append('HWY_Non_Motorized.skm')

HSKM_OMX_names = [hskm_prefix + "_" + t + "_" + hm + '.omx' for t in time_periods for hm in hwy_modes]
HSKM_OMX_names.append('HWY_Non_Motorized.omx')

### Loop through Transit SKMs and convert to OMXs
#for cube_skm in TSKM_names:
#    
#    skm_file_path = os.path.join(CubeSkimDir, cube_skm)
#    out_file_path = os.path.join(OutputDir, cube_skm)
#    # Copy SKM files to output directory
#    if os.path.exists(skm_file_path):
#        copyfile(skm_file_path, out_file_path)
#    # convert to OMX format
#    if os.path.exists(out_file_path):
#        cmd = cube_to_emme_exe + ' ' + out_file_path
#        os.system(cmd)
#        os.remove(out_file_path)

## Add zone mapping to OMX skims
for omx_skm in TSKM_OMX_names:
    
    omx_file_path = os.path.join(OutputDir, omx_skm)
    # Add mapping to zone file if exists
    if os.path.exists(omx_file_path):
        omx_file = omx.open_file(omx_file_path, 'a')
        if not 'ZoneID' in omx_file.list_mappings():
            omx_file.create_mapping('ZoneID', np.arange(1,3723))
        omx_file.close() 


### Loop through Highway SKMs and convert to OMXs
#for cube_skm in HSKM_names:
#    
#    skm_file_path = os.path.join(CubeSkimDir, cube_skm)
#    out_file_path = os.path.join(OutputDir, cube_skm)
#    # Copy SKM files to output directory
#    if os.path.exists(skm_file_path):
#        copyfile(skm_file_path, out_file_path)
#    # convert to OMX format
#    if os.path.exists(out_file_path):
#        cmd = cube_to_emme_exe + ' ' + out_file_path
#        os.system(cmd)
#        os.remove(out_file_path)

## Add zone mapping to OMX skims
for omx_skm in HSKM_OMX_names:
    
    omx_file_path = os.path.join(OutputDir, omx_skm)
    # Add mapping to zone file if exists
    if os.path.exists(omx_file_path):
        omx_file = omx.open_file(omx_file_path, 'a')
        if not 'ZoneID' in omx_file.list_mappings():
            omx_file.create_mapping('ZoneID', np.arange(1,3723))
        omx_file.close() 
        
## Add zone mapping to OMX skims
HSKM_OMX_names = ['atype.omx', 'county.omx']
for omx_skm in HSKM_OMX_names:
    
    omx_file_path = os.path.join(OutputDir, omx_skm)
    # Add mapping to zone file if exists
    if os.path.exists(omx_file_path):
        omx_file = omx.open_file(omx_file_path, 'a')
        if not 'ZoneID' in omx_file.list_mappings():
            omx_file.create_mapping('ZoneID', np.arange(1,3723))
        omx_file.close() 
        