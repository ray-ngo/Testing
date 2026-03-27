import pandas as pd, numpy as np
import sys, os
from simpledbf import Dbf5

scen_dir = sys.argv[1]
lu_data_dir = os.path.join(scen_dir, 'inputs\landuse')
extra_data_dir = os.path.join(scen_dir, 'outputs\landuse')

#read landuse
lu = pd.read_csv(os.path.join(lu_data_dir, f'land_use.csv'))

for c in ['PRKCST', 'OPRKCST', 'TERMINAL', 'AREATYPE']:
    if c in lu.columns:
        lu.drop(columns = c, inplace = True)

#read parking and areatype
parking = pd.read_csv(os.path.join(extra_data_dir, 'ZONEV2.A2F'), sep='\s+', header=None)
parking.columns = ['TAZ', 'HBWParkCost', 'HBSParkCost', 'HBOParkCost', 'NHBParkCost', 'HB_TermTime', 'NHB_TermTime']

areatype = Dbf5(os.path.join(extra_data_dir, 'AreaType_File.dbf'))
areatype = areatype.to_dataframe()

#merge
lu = pd.merge(lu, parking[['TAZ', 'HBWParkCost', 'HBSParkCost', 'HB_TermTime']], on = 'TAZ', how = 'left')
lu = pd.merge(lu, areatype[['TAZ', 'ATYPE']], on = 'TAZ', how = 'left')

lu.rename(columns={'HBWParkCost':'PRKCST', 'HBSParkCost':'OPRKCST', 'HB_TermTime':'TERMINAL', 'ATYPE':'AREATYPE'}, inplace=True)
lu['PRKCST'] = lu['PRKCST']/8.0

lu.to_csv(os.path.join(lu_data_dir, 'land_use.csv'), index=False)
