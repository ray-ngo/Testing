# -*- coding: utf-8 -*-
"""
Created on July 6, 2023

This script is created to create region-level "View-from-Space" statistics for one to several Gen3 Model run. These
statistics include most ABM statistics generated for the ABM Visualizer, highway assignment summaries generated from
loaded highway network, and transit assignment summaries generated from transit link volume files and stop-to-stop
volume files.

@author: fxie
"""
import sys, os, re
import numpy as np
import pandas as pd
from simpledbf import Dbf5

scen_dir = os.environ.get('SCEN_DIRECTORY')
scenarionm = os.environ.get('_year_')
abm_sum_dir = os.environ.get("ABM_SUMMARY_DIR")

pd.options.mode.chained_assignment = None  # default='warn'

df_vfs = pd.DataFrame()



### VIEW FROM SPACE SUMMARIES FOR EACH SCENARIO ###
#Scenario name and path
scen_info = pd.Series({'scenario': scenarionm, 'path': scen_dir})

print("- Extracting ABM overview summaries...")
### Overview Summaries
df_totals = pd.read_csv(os.path.join(abm_sum_dir, "totals.csv"))
totals = df_totals.set_index('name')['value']

Total_population=totals['total_population']
Total_households=totals['total_households']
Total_tours=totals['total_tours']
Total_trips=totals['total_trips']
Total_stops=totals['total_stops']
Tours_per_Person=Total_tours/Total_population
Trips_per_Person=Total_trips/Total_population
Stops_per_Person=Total_stops/Total_population
Trips_per_Household=Total_trips/Total_households

totals = totals.set_axis(['total population','total households','total tours','total trips','total person stops','total vmt'])
totals = pd.concat([totals, pd.Series({'tours per person':Tours_per_Person,'trips per person':Trips_per_Person,'stops per person':Stops_per_Person,'trips per household':Trips_per_Household})])
#totals = totals.apply(lambda x: format_num(x))
#totals[:,-4:] = totals[:,-4:].apply(lambda x: format_float(x))
#Insert title line
totals=pd.concat([pd.Series({'I. Overview':""}),totals])

# Employment data from cooperative land use forecasts
df_lu = pd.read_csv(os.path.join(scen_dir, r"inputs\landuse\land_use.csv"))
emp = df_lu.loc[:,['INDEMP','RETEMP','OFFEMP','OTHEMP','TOTEMP']].sum(axis=0)
emp = emp.set_axis(['industrial','retail','office','other','total employment'])
pct_emp=emp[:-1]/emp['total employment']
pct_emp=pct_emp.set_axis(['% industrial','% retail','% office','% other'])
emp = pd.concat([emp, pct_emp])
#Insert title line
emp=pd.concat([pd.Series({'Employment by category':""}),emp])

#Distribution of population by person type
df_pertypeDistbn = pd.read_csv(os.path.join(abm_sum_dir, "pertypeDistbn.csv"))
pertypeDistbn = pd.Series(df_pertypeDistbn['freq'].values, index=['FT Worker','PT Worker','Univ Student','Non-Worker','Retiree','Driving-age Student','Non-driving-age Student','Pre-Schooler'])
pct_pertypeDistbn=pertypeDistbn/Total_population
pertypeDistbn = pd.concat([pertypeDistbn, pd.Series({'total population':Total_population})])
pct_pertypeDistbn=pct_pertypeDistbn.set_axis(['% FT Worker','% PT Worker','% Univ Student','% Non-Worker','% Retiree','% Driving-age Student','% Non-driving-age Student','% Pre-Schooler'])
pertypeDistbn = pd.concat([pertypeDistbn, pct_pertypeDistbn])
#Insert title line
pertypeDistbn = pd.concat([pd.Series({'Persons by person type':""}),pertypeDistbn])

#Distribution of non-GQ households by size
df_hhSizeDist = pd.read_csv(os.path.join(abm_sum_dir, "hhSizeDist.csv"))
hhSizeDist = pd.Series(df_hhSizeDist['freq'].values, index=['1 person','2 persons','3 persons','4+ persons'])
non_GQ_hh_total = hhSizeDist.sum()
pct_hhSizeDist=hhSizeDist/non_GQ_hh_total
pct_hhSizeDist=pct_hhSizeDist.set_axis(['% 1 person','% 2 persons','% 3 persons','% 4+ persons'])
hhSizeDist = pd.concat([hhSizeDist, pd.Series({'total non-GQ households':non_GQ_hh_total}),pct_hhSizeDist])
#Insert title line
hhSizeDist = pd.concat([pd.Series({'Non-GQ households by size':""}),hhSizeDist])

#Distribution of households by income
df_hhIncomeDist = pd.read_csv(os.path.join(abm_sum_dir, "hhIncomeDist.csv"))
hhIncomeDist = pd.Series(df_hhIncomeDist['freq'].values, index=['<$50,000', '$50,000-$99,999', '$100,000-$149,999', '$150,000 and above'])
hh_income_total = hhIncomeDist.sum()
pct_hhIncomeDist = hhIncomeDist / hh_income_total
pct_hhIncomeDist = pct_hhIncomeDist.set_axis(['% <$50,000', '% $50,000-$99,999', '% $100,000-$149,999', '% $150,000 and above'])
hhIncomeDist = pd.concat([hhIncomeDist, pd.Series({'total households': hh_income_total}), pct_hhIncomeDist])
hhIncomeDist = pd.concat([pd.Series({'households by income': ""}), hhIncomeDist])


print("- Extracting ABM long-term model summaries...")

### Long-term summaries

#Distribution of households by car ownership
df_autoOwnership = pd.read_csv(os.path.join(abm_sum_dir, "autoOwnership.csv"))
autoOwnership = pd.Series(df_autoOwnership['freq'].values, index=['0 car','1 car','2 cars','3 cars','4+ cars'])
hh_total = autoOwnership.sum()
pct_autoOwnership=autoOwnership/hh_total
pct_autoOwnership=pct_autoOwnership.set_axis(['% 0 car','% 1 car','% 2 cars','% 3 cars','% 4+ cars'])
autoOwnership = pd.concat([autoOwnership, pd.Series({'total households':hh_total}), pct_autoOwnership])
#Insert title line
autoOwnership = pd.concat([pd.Series({'II. Long-Term Model Summaries':"",'Households by car ownership':""}),autoOwnership])

#Work from home
df_wfh = pd.read_csv(os.path.join(abm_sum_dir, "wfh_summary.csv"))
workers = df_wfh.iloc[-1,-2]
wfh_workers =  df_wfh.iloc[-1,-1]
pct_wfh = wfh_workers/workers
wfh = pd.Series([wfh_workers, workers,pct_wfh], index=['wfh workers','total workers','% wfh workers'])
#Insert title line
wfh = pd.concat([pd.Series({'Work from home (wfh)':""}),wfh])

#Telecommute Frequency
df_telecommuteFrequency = pd.read_csv(os.path.join(abm_sum_dir, "telecommuteFrequency.csv"))
telecommuteFrequency = pd.Series(df_telecommuteFrequency['freq'].values, index=['1 day a week','2 to 3 days a week','4 days a week','No telecommute'])
commuters_total = telecommuteFrequency.sum()
pct_telecommuteFrequency=telecommuteFrequency/commuters_total
pct_telecommuteFrequency=pct_telecommuteFrequency.set_axis(['% 1 day a week','% 2 to 3 days a week','% 4 days a week','% No telecommute'])
telecommuteFrequency = pd.concat([telecommuteFrequency, pd.Series({'total workers':commuters_total}), pct_telecommuteFrequency])
#Insert title line
telecommuteFrequency = pd.concat([pd.Series({'Telecommute Frequency':""}),telecommuteFrequency])

# Average Mandatory Tour Lengths
df_mandTourLengths = pd.read_csv(os.path.join(abm_sum_dir, "mandTourLengths.csv"))
work_TourLength = df_mandTourLengths.iloc[-1,-6]
univ_TourLength = df_mandTourLengths.iloc[-1,-5]
school_TourLength = df_mandTourLengths.iloc[-1,-4]
mandTourLengths = pd.Series([work_TourLength, univ_TourLength,school_TourLength], index=['work tour length','university tour length','school tour length'])
#Insert title line
mandTourLengths = pd.concat([pd.Series({'Average mandatory tour lengths in miles':""}),mandTourLengths])

print("- Extracting ABM tour-level summaries...")
### Tour-level summaries

# Daily Activity Pattern (DAP)
df_dapSummary = pd.read_csv(os.path.join(abm_sum_dir, "dapSummary_vis.csv"))
M = df_dapSummary.loc[(df_dapSummary['PERTYPE'] == 'Total') & (df_dapSummary['DAP'] == "M"), 'freq'].values[0]
H = df_dapSummary.loc[(df_dapSummary['PERTYPE'] == 'Total') & (df_dapSummary['DAP'] == "H"), 'freq'].values[0]
N = df_dapSummary.loc[(df_dapSummary['PERTYPE'] == 'Total') & (df_dapSummary['DAP'] == "N"), 'freq'].values[0]
dapSummary = pd.Series([M, N, H], index=['Mandatory','Non-Mandatory','Home'])
pop_total = dapSummary.sum()
pct_dapSummary=dapSummary/pop_total
pct_dapSummary=pct_dapSummary.set_axis(['% Mandatory','% Non-Mandatory','% Home'])
dapSummary = pd.concat([dapSummary, pd.Series({'total population':pop_total}), pct_dapSummary])
#Insert title line
dapSummary = pd.concat([pd.Series({'III. Tour-Level Summaries':"",'Persons by Daily Activity Pattern (DAP)':""}),dapSummary])

# Mandatory Tour Frequency
df_mtfSummary = pd.read_csv(os.path.join(abm_sum_dir, "mtfSummary_vis.csv"))
mtfSummary = pd.Series(df_mtfSummary.loc[(df_mtfSummary['PERTYPE'] == 'Total'), 'freq'].values,index=['1 work tour','2 work tours','1 school tour','2 school tours','1 work & 1 school'])
mt_total = mtfSummary.sum()
pct_mtfSummary=mtfSummary/mt_total
pct_mtfSummary=pct_mtfSummary.set_axis(['% 1 work tour','% 2 work tours','% 1 school tour','% 2 school tours','% 1 work & 1 school'])
mtfSummary = pd.concat([mtfSummary, pd.Series({'total mandatory tours':mt_total}), pct_mtfSummary])
#Insert title line
mtfSummary = pd.concat([pd.Series({'Mandatory tours by purpose & frequency':""}),mtfSummary])

#Tour rate by person type (active persons only)
df_tours_by_pertype = pd.read_csv(os.path.join(abm_sum_dir, "total_tours_by_pertype_vis.csv"))
df_activepsn_by_pertype = pd.read_csv(os.path.join(abm_sum_dir, "activePertypeDistbn.csv"))
tour_rates = df_tours_by_pertype['freq'].values/df_activepsn_by_pertype['freq'].values
tour_rate_by_pertype = pd.Series(tour_rates, index=['FT Worker','PT Worker','Univ Student','Non-Worker','Retiree','Driving-age Student','Non-driving-age Student','Pre-Schooler'])
#Insert title line
tour_rate_by_pertype = pd.concat([pd.Series({'Tour rate by person type (active persons only)':""}),tour_rate_by_pertype])

#Persons by frequency of individual Non-Mandatory tours
df_inmSummary = pd.read_csv(os.path.join(abm_sum_dir, "inmSummary_vis.csv"))
inmSummary = pd.Series(df_inmSummary.loc[(df_inmSummary['PERTYPE'] == 'Total'), 'freq'].values,index=['0 tour','1 tour','2 tours','3+ tours'])
psn_total = inmSummary.sum()
pct_inmSummary=inmSummary/psn_total
pct_inmSummary=pct_inmSummary.set_axis(['% 0 tour','% 1 tour','% 2 tours','% 3+ tours'])
inmSummary = pd.concat([inmSummary, pd.Series({'total population':psn_total}), pct_inmSummary])
#Insert title line
inmSummary = pd.concat([pd.Series({'Persons by frequency of Non-Mandatory tours':""}),inmSummary])

#Joint tours by tour composition
df_jointComp = pd.read_csv(os.path.join(abm_sum_dir, "jointComp.csv"))
jtours_by_jointComp = pd.Series(df_jointComp['freq'].values, index=df_jointComp['tour_composition'].values)
total_jtours = jtours_by_jointComp.sum()
pct_jtours_by_jointComp=jtours_by_jointComp/total_jtours
pct_jtours_by_jointComp=pct_jtours_by_jointComp.set_axis(['% All Adult','% All Children','% Mixed'])
jtours_by_jointComp = pd.concat([jtours_by_jointComp, pd.Series({'total joint tours':total_jtours}), pct_jtours_by_jointComp])
#Insert title line
jtours_by_jointComp = pd.concat([pd.Series({'Joint tours by tour composition':""}),jtours_by_jointComp])

#Joint tours by party size
df_jointPartySize = pd.read_csv(os.path.join(abm_sum_dir, "jointPartySize.csv"))
jtours_by_jointPartySize = pd.Series(df_jointPartySize['freq'].values, index=['2 HH members','3 HH members','4 HH members','5 HH members'])
total_jtours = jtours_by_jointPartySize.sum()
pct_jtours_by_jointPartySize=jtours_by_jointPartySize/total_jtours
pct_jtours_by_jointPartySize=pct_jtours_by_jointPartySize.set_axis(['% 2 HH members','% 3 HH members','% 4 HH members','% 5 HH members'])
jtours_by_jointPartySize = pd.concat([jtours_by_jointPartySize, pd.Series({'total joint tours':total_jtours}), pct_jtours_by_jointPartySize])
#Insert title line
jtours_by_jointPartySize = pd.concat([pd.Series({'Joint tours by party size':""}),jtours_by_jointPartySize])

#Average Non-Mandatory tour lengths (Miles)
df_nonMandTourLengths = pd.read_csv(os.path.join(abm_sum_dir, "nonMandTourLengths.csv"))
nonMandTourLengths = pd.Series(df_nonMandTourLengths['avgTourLength'].values, index=[
    'Escorting','Indi-Maintenance','Indi-Discretionary','Joint-Maintenance','Joint-Discretionary','At-Work','All Tours'])
#Insert title line
nonMandTourLengths = pd.concat([pd.Series({'Average Non-Mandatory tour lengths (Miles)':""}),nonMandTourLengths])

#Tour departures by TOD
df_todProfile = pd.read_csv(os.path.join(abm_sum_dir, "todProfile_vis.csv"))

"""
Assign 48 half-hours (1-18) into 5 time of day periods (NT1,AM,MD,PM,NT2)
**Aggregate Tour Arrival-Departure**
NT1: 3:00 AM to 5:59 AM (1-6)
AM: 6:00 AM to 8:59 AM (7-12)
MD: 9:00 AM to 2:59 PM (13-24)
PM: 3:00 PM to 6:59 PM (25-32)
NT2: 7:00 PM to 2:59 AM (33-48)
"""

tod_48=np.repeat(['NT1'],6).tolist() + np.repeat(['AM'],6).tolist() + np.repeat(['MD'],12).tolist()  + np.repeat(['PM'],8).tolist()  + np.repeat(['NT2'],16).tolist()
todProfile_dep_48 = pd.Series(df_todProfile.loc[(df_todProfile['purpose'] == 'Total'), 'freq_dep'].values,index=tod_48)
todProfile_dep = todProfile_dep_48.groupby(level=0).sum()
todProfile_dep = todProfile_dep.reindex(index = ['NT1','AM','MD','PM','NT2'])
total_tour_departures = todProfile_dep.sum()
pct_todProfile_dep=todProfile_dep/total_tour_departures
pct_todProfile_dep=pct_todProfile_dep.set_axis(['% NT1','% AM','% MD','% PM','% NT2'])
todProfile_dep = pd.concat([todProfile_dep, pd.Series({'total tour departures':total_tour_departures}), pct_todProfile_dep])
#Insert title line
todProfile_dep = pd.concat([pd.Series({'Tour departures by TOD':""}),todProfile_dep])

#Tour arrivals by TOD
todProfile_arr_48 = pd.Series(df_todProfile.loc[(df_todProfile['purpose'] == 'Total'), 'freq_arr'].values,index=tod_48)
todProfile_arr = todProfile_arr_48.groupby(level=0).sum()
todProfile_arr = todProfile_arr.reindex(index = ['NT1','AM','MD','PM','NT2'])
total_tour_arrartures = todProfile_arr.sum()
pct_todProfile_arr=todProfile_arr/total_tour_arrartures
pct_todProfile_arr=pct_todProfile_arr.set_axis(['% NT1','% AM','% MD','% PM','% NT2'])
todProfile_arr = pd.concat([todProfile_arr, pd.Series({'total tour arrivals':total_tour_arrartures}), pct_todProfile_arr])
#Insert title line
todProfile_arr = pd.concat([pd.Series({'Tour arrivals by TOD':""}),todProfile_arr])

#Tours by tour mode
df_tmodeProfile = pd.read_csv(os.path.join(abm_sum_dir, "tmodeProfile_vis.csv"))
tmodeProfile = pd.Series(df_tmodeProfile.loc[(df_tmodeProfile['purpose'] == 'Total'), 'freq_all'].values,index=[
    'Auto SOV','Ride Hail','Auto HOV2','Auto HOV3+','Walk','Bike','Walk-Transit','PNR-Transit','KNR-Transit','School Bus'])
tmodeProfile = tmodeProfile.reindex(index = ['Auto SOV','Auto HOV2','Auto HOV3+','Walk','Bike','Walk-Transit','PNR-Transit','KNR-Transit','School Bus','Ride Hail'])
total_tours = tmodeProfile.sum()
pct_tmodeProfile=tmodeProfile/total_tours
pct_tmodeProfile=pct_tmodeProfile.set_axis(['% Auto SOV','% Auto HOV2','% Auto HOV3+','% Walk','% Bike','% Walk-Transit','% PNR-Transit','% KNR-Transit','% School Bus','% Ride Hail'])
tmodeProfile = pd.concat([tmodeProfile, pd.Series({'total tours':total_tours}), pct_tmodeProfile])
#Insert title line
tmodeProfile = pd.concat([pd.Series({'Tours by tour mode':""}),tmodeProfile])

#Work tours by tour mode
tmodeProfile_work = pd.Series(df_tmodeProfile.loc[(df_tmodeProfile['purpose'] == 'work'), 'freq_all'].values,index=[
    'Auto SOV','Ride Hail','Auto HOV2','Auto HOV3+','Walk','Bike','Walk-Transit','PNR-Transit','KNR-Transit','School Bus'])
tmodeProfile_work = tmodeProfile_work.reindex(index = ['Auto SOV','Auto HOV2','Auto HOV3+','Walk','Bike','Walk-Transit','PNR-Transit','KNR-Transit','School Bus','Ride Hail'])
total_work_tours = tmodeProfile_work.sum()
pct_tmodeProfile_work=tmodeProfile_work/total_work_tours
pct_tmodeProfile_work=pct_tmodeProfile_work.set_axis(['% Auto SOV','% Auto HOV2','% Auto HOV3+','% Walk','% Bike','% Walk-Transit','% PNR-Transit','% KNR-Transit','% School Bus','% Ride Hail'])
tmodeProfile_work = pd.concat([tmodeProfile_work, pd.Series({'total work tours':total_work_tours}), pct_tmodeProfile_work])
#Insert title line
tmodeProfile_work = pd.concat([pd.Series({'Work tours by tour mode':""}),tmodeProfile_work])

print("- Extracting ABM trip-level summaries...")

#Outbound half-tours by stop frequency
df_stopfreqDir = pd.read_csv(os.path.join(abm_sum_dir, "stopfreqDir_vis.csv"))
stopfreqDir_out = pd.Series(df_stopfreqDir.loc[(df_stopfreqDir['purpose'] == 'Total'), 'freq_out'].values,index=['0 stop','1 stop','2 stops','3+ stops'])
total_out_tours = stopfreqDir_out.sum()
pct_stopfreqDir_out=stopfreqDir_out/total_out_tours
pct_stopfreqDir_out=pct_stopfreqDir_out.set_axis(['% 0 stop','% 1 stop','% 2 stops','% 3+ stops'])
stopfreqDir_out = pd.concat([stopfreqDir_out, pd.Series({'total outbound tours':total_out_tours}), pct_stopfreqDir_out])
#Insert title line
stopfreqDir_out = pd.concat([pd.Series({'IV. Trip-Level Summaries':"",'Outbound half-tours by stop frequency':""}),stopfreqDir_out])

#Inbound half-tours by stop frequency
stopfreqDir_in = pd.Series(df_stopfreqDir.loc[(df_stopfreqDir['purpose'] == 'Total'), 'freq_inb'].values,index=['0 stop','1 stop','2 stops','3+ stops'])
total_in_tours = stopfreqDir_in.sum()
pct_stopfreqDir_in=stopfreqDir_in/total_in_tours
pct_stopfreqDir_in=pct_stopfreqDir_in.set_axis(['% 0 stop','% 1 stop','% 2 stops','% 3+ stops'])
stopfreqDir_in = pd.concat([stopfreqDir_in, pd.Series({'total inbound tours':total_in_tours}), pct_stopfreqDir_in])
#Insert title line
stopfreqDir_in = pd.concat([pd.Series({'Inbound half-tours by stop frequency':""}),stopfreqDir_in])

#Tours by stop frequency
df_stopfreq_total = pd.read_csv(os.path.join(abm_sum_dir, "stopfreq_total_vis.csv"))
stopfreq_total = pd.Series(df_stopfreq_total.loc[(df_stopfreq_total['purpose'] == 'Total'), 'freq'].values,index=['0 stop','1 stop','2 stops','3 stops','4 stops','5 stops','6+ stops'])
total_tours = stopfreq_total.sum()
pct_stopfreq_total=stopfreq_total/total_tours
pct_stopfreq_total=pct_stopfreq_total.set_axis(['% 0 stop','% 1 stop','% 2 stops','% 3 stops','% 4 stops','% 5 stops','% 6+ stops'])
stopfreq_total = pd.concat([stopfreq_total, pd.Series({'total tours':total_tours}), pct_stopfreq_total])
#Insert title line
stopfreq_total = pd.concat([pd.Series({'Tours by stop frequency':""}),stopfreq_total])

#Stops by stop purpose
df_stoppurpose = pd.read_csv(os.path.join(abm_sum_dir, "stoppurpose_tourpurpose_vis.csv"))
stoppurpose = pd.Series(df_stoppurpose.loc[(df_stoppurpose['purpose'] == 'Total'), 'freq'].values,index=[
    'Work','At-Work','University','School','Escorting','Shopping','Maintenance','Eating','Visitor','Discretionary'])
stoppurpose = stoppurpose.reindex(index = ['Work','University','School','Escorting','Shopping','Maintenance','Eating','Visitor','Discretionary','At-Work'])
total_stops = stoppurpose.sum()
pct_stoppurpose=stoppurpose/total_stops
pct_stoppurpose=pct_stoppurpose.set_axis(['% Work','% University','% School','% Escorting','% Shopping','% Maintenance','% Eating','% Visitor','% Discretionary','% At-Work'])
stoppurpose = pd.concat([stoppurpose, pd.Series({'total trip stops':total_stops}), pct_stoppurpose])
#Insert title line
stoppurpose = pd.concat([pd.Series({'Stops by stop purpose':""}),stoppurpose])

#Average out-of-direction distance by tour purpose
df_ood_dist_by_purp = pd.read_csv(os.path.join(abm_sum_dir, "avgStopOutofDirectionDist_vis.csv"))
ood_dist_by_purp = pd.Series(df_ood_dist_by_purp['avgDist'].values,index=[
    'Work','University','School','Escorting','Indi-Maintenance','Indi-Discretionary','Joint-Maintenance','Joint-Discretionary','At-Work','total average distance'])
#Insert title line
ood_dist_by_purp = pd.concat([pd.Series({'Aver. out-of-direction dist. by tour purpose':""}),ood_dist_by_purp])

#Stop departures by TOD
df_stopTripDep = pd.read_csv(os.path.join(abm_sum_dir, "stopTripDep_vis.csv"))
df_stopTripDep.sort_values(by=['purpose', 'id'], axis=0, ascending=[False, True], inplace=True,
               ignore_index=True, key=None)
#print(df_stopTripDep.to_string())
#Similar to tours by TOD, assign 48 half-hours (1-18) in a day into 5 time of day periods (NT1,AM,MD,PM,NT2)
stopTripDep_sdep_48 = pd.Series(df_stopTripDep.loc[(df_stopTripDep['purpose'] == 'Total'), 'freq_stop'].values[0:48],index=tod_48)
#Group by index (time of day periods)
stopTripDep_sdep = stopTripDep_sdep_48.groupby(level=0).sum()
stopTripDep_sdep = stopTripDep_sdep.reindex(index = ['NT1','AM','MD','PM','NT2'])
total_stop_departures = stopTripDep_sdep.sum()
pct_stopTripDep_sdep=stopTripDep_sdep/total_stop_departures
pct_stopTripDep_sdep=pct_stopTripDep_sdep.set_axis(['% NT1','% AM','% MD','% PM','% NT2'])
stopTripDep_sdep = pd.concat([stopTripDep_sdep, pd.Series({'total trip stop departures':total_stop_departures}), pct_stopTripDep_sdep])
#Insert title line
stopTripDep_sdep = pd.concat([pd.Series({'Stop departures by TOD':""}),stopTripDep_sdep])

#Trip departures by TOD
stopTripDep_tdep_48 = pd.Series(df_stopTripDep.loc[(df_stopTripDep['purpose'] == 'Total'), 'freq_trip'].values[0:48],index=tod_48)
#Group by index (time of day periods)
stopTripDep_tdep = stopTripDep_tdep_48.groupby(level=0).sum()
stopTripDep_tdep = stopTripDep_tdep.reindex(index = ['NT1','AM','MD','PM','NT2'])
total_trip_departures = stopTripDep_tdep.sum()
pct_stopTripDep_tdep=stopTripDep_tdep/total_trip_departures
pct_stopTripDep_tdep=pct_stopTripDep_tdep.set_axis(['% NT1','% AM','% MD','% PM','% NT2'])
stopTripDep_tdep = pd.concat([stopTripDep_tdep, pd.Series({'total trip departures':total_trip_departures}), pct_stopTripDep_tdep])
#Insert title line
stopTripDep_tdep = pd.concat([pd.Series({'Trip departures by TOD':""}),stopTripDep_tdep])



#Trips by trip mode
df_tripModeProfile = pd.read_csv(os.path.join(abm_sum_dir, "tripModeProfile_vis.csv"))
df_tripModeProfile_total=df_tripModeProfile.loc[((df_tripModeProfile['tourmode'] == 'Total') & (df_tripModeProfile['purpose'] == 'total'))]
tripModeProfile = pd.Series(df_tripModeProfile_total['value'].values,index=[
    'Auto SOV','Ride Hail','Auto HOV2','Auto HOV3+','Walk','Bike','Walk-Transit','PNR-Transit','KNR-Transit','School Bus'])
tripModeProfile = tripModeProfile.reindex(index = ['Auto SOV','Auto HOV2','Auto HOV3+','Walk','Bike','Walk-Transit','PNR-Transit','KNR-Transit','School Bus','Ride Hail'])
total_trips = tripModeProfile.sum()
pct_tripModeProfile=tripModeProfile/total_trips
pct_tripModeProfile=pct_tripModeProfile.set_axis(['% Auto SOV','% Auto HOV2','% Auto HOV3+','% Walk','% Bike','% Walk-Transit','% PNR-Transit','% KNR-Transit','% School Bus','% Ride Hail'])
tripModeProfile = pd.concat([tripModeProfile, pd.Series({'total trips':total_trips}), pct_tripModeProfile])
#Insert title line
tripModeProfile = pd.concat([pd.Series({'Trips by trip mode':""}),tripModeProfile])

##Work trips by trip mode
tripModeProfile_wt_total=df_tripModeProfile.loc[((df_tripModeProfile['tourmode'] == 'Total') & (df_tripModeProfile['purpose'] == 'work'))]
tripModeProfile_wt = pd.Series(tripModeProfile_wt_total['value'].values,index=[
    'Auto SOV','Ride Hail','Auto HOV2','Auto HOV3+','Walk','Bike','Walk-Transit','PNR-Transit','KNR-Transit','School Bus'])
tripModeProfile_wt = tripModeProfile_wt.reindex(index = ['Auto SOV','Auto HOV2','Auto HOV3+','Walk','Bike','Walk-Transit','PNR-Transit','KNR-Transit','School Bus','Ride Hail'])
total_trips_wt = tripModeProfile_wt.sum()
pct_tripModeProfile_wt=tripModeProfile_wt/total_trips_wt
pct_tripModeProfile_wt=pct_tripModeProfile_wt.set_axis(['% Auto SOV','% Auto HOV2','% Auto HOV3+','% Walk','% Bike','% Walk-Transit','% PNR-Transit','% KNR-Transit','% School Bus','% Ride Hail'])
tripModeProfile_wt = pd.concat([tripModeProfile_wt, pd.Series({'total trips on work tours':total_trips_wt}), pct_tripModeProfile_wt])
#Insert title line
tripModeProfile_wt = pd.concat([pd.Series({'Trips on work tours by trip mode':""}),tripModeProfile_wt])

print("- Generating highway assignment summaries...")


#External/Exogenous Trips
df_external = pd.read_csv(os.path.join(scen_dir, r"outputs\auxiliary\SUMMARY_EXT_EXO_TRIPS.csv"))
external_trips = pd.Series(df_external['    Autodriver Trips'].values, index=df_external['Description         '].values)
external_trips = pd.concat([pd.Series({'V. Exogenous Trip Summary':""}),external_trips])

### Highway Assignment Summaries
df_hwy_net = pd.read_csv(os.path.join(scen_dir, r"outputs\hwy_net\i4_Assign_Output.csv"))
df_hwy_net_filtered = df_hwy_net[df_hwy_net['FTYPE'] >0]
df_hwy_net_filtered['I4AMVMT'] = df_hwy_net_filtered['I4AMVOL'] * df_hwy_net_filtered['DISTANCE']
df_hwy_net_filtered['I4MDVMT'] = df_hwy_net_filtered['I4MDVOL'] * df_hwy_net_filtered['DISTANCE']
df_hwy_net_filtered['I4PMVMT'] = df_hwy_net_filtered['I4PMVOL'] * df_hwy_net_filtered['DISTANCE']
df_hwy_net_filtered['I4NTVMT'] = df_hwy_net_filtered['I4NTVOL'] * df_hwy_net_filtered['DISTANCE']
df_hwy_net_filtered['I424VMT'] = df_hwy_net_filtered['I424VOL'] * df_hwy_net_filtered['DISTANCE']
df_hwy_net_filtered['I4AMVHT'] = df_hwy_net_filtered['DISTANCE'] / df_hwy_net_filtered['I4AMSPD'] * df_hwy_net_filtered['I4AMVOL']
df_hwy_net_filtered['I4MDVHT'] = df_hwy_net_filtered['DISTANCE'] / df_hwy_net_filtered['I4MDSPD'] * df_hwy_net_filtered['I4MDVOL']
df_hwy_net_filtered['I4PMVHT'] = df_hwy_net_filtered['DISTANCE'] / df_hwy_net_filtered['I4PMSPD'] * df_hwy_net_filtered['I4PMVOL']
df_hwy_net_filtered['I4NTVHT'] = df_hwy_net_filtered['DISTANCE'] / df_hwy_net_filtered['I4NTSPD'] * df_hwy_net_filtered['I4NTVOL']
df_hwy_net_filtered['I4AMVHTFFS'] = df_hwy_net_filtered['DISTANCE'] / df_hwy_net_filtered['I4AMFFSPD'] * df_hwy_net_filtered['I4AMVOL']
df_hwy_net_filtered['I4MDVHTFFS'] = df_hwy_net_filtered['DISTANCE'] / df_hwy_net_filtered['I4MDFFSPD'] * df_hwy_net_filtered['I4MDVOL']
df_hwy_net_filtered['I4PMVHTFFS'] = df_hwy_net_filtered['DISTANCE'] / df_hwy_net_filtered['I4PMFFSPD'] * df_hwy_net_filtered['I4PMVOL']
df_hwy_net_filtered['I4NTVHTFFS'] = df_hwy_net_filtered['DISTANCE'] / df_hwy_net_filtered['I4NTFFSPD'] * df_hwy_net_filtered['I4NTVOL']
df_hwy_net_filtered['I4AMVHD'] = df_hwy_net_filtered['I4AMVHT'] - df_hwy_net_filtered['I4AMVHTFFS']
df_hwy_net_filtered['I4MDVHD'] = df_hwy_net_filtered['I4MDVHT'] - df_hwy_net_filtered['I4MDVHTFFS']
df_hwy_net_filtered['I4PMVHD'] = df_hwy_net_filtered['I4PMVHT'] - df_hwy_net_filtered['I4PMVHTFFS']
df_hwy_net_filtered['I4NTVHD'] = df_hwy_net_filtered['I4NTVHT'] - df_hwy_net_filtered['I4NTVHTFFS']

# VMT by facility type
vmt_by_ft = df_hwy_net_filtered.groupby('FTYPE')['I424VMT'].sum()
vmt_by_ft = vmt_by_ft.set_axis(['freeway','major arterial','minor arterial','collector','expressway','ramp'])
vmt_total = vmt_by_ft.sum()
pct_vmt_by_ft = vmt_by_ft/vmt_total
pct_vmt_by_ft = pct_vmt_by_ft.set_axis(['% freeway','% major arterial','% minor arterial','% collector','% expressway','% ramp'])
vmt_by_ft = pd.concat([vmt_by_ft, pd.Series({'Total VMT': vmt_total}), pct_vmt_by_ft])
#Insert title line
vmt_by_ft = pd.concat([pd.Series({'VI. Highway Assignment Summaries':"",'VMT by facility type':""}),vmt_by_ft])

# VMT by time of day
vmt_am=df_hwy_net_filtered['I4AMVMT'].sum()
vmt_md=df_hwy_net_filtered['I4MDVMT'].sum()
vmt_pm=df_hwy_net_filtered['I4PMVMT'].sum()
vmt_nt=df_hwy_net_filtered['I4NTVMT'].sum()
vmt_by_tod=pd.Series([vmt_am,vmt_md,vmt_pm,vmt_nt],index=['AM VMT','MD VMT','PM VMT','NT VMT'])
pct_vmt_by_tod = vmt_by_tod/vmt_total
pct_vmt_by_tod = pct_vmt_by_tod.set_axis(['% AM VMT','% MD VMT','% PM VMT','% NT VMT'])
vmt_by_tod = pd.concat([vmt_by_tod, pd.Series({'Total VMT': vmt_total}), pct_vmt_by_tod])
#Insert title line
vmt_by_tod = pd.concat([pd.Series({'VMT by time of day':""}),vmt_by_tod])

# VHT by time of day
vht_am=df_hwy_net_filtered['I4AMVHT'].sum()
vht_md=df_hwy_net_filtered['I4MDVHT'].sum()
vht_pm=df_hwy_net_filtered['I4PMVHT'].sum()
vht_nt=df_hwy_net_filtered['I4NTVHT'].sum()
vht_total=vht_am+vht_md+vht_pm+vht_nt
vht_by_tod=pd.Series([vht_am,vht_md,vht_pm,vht_nt],index=['AM VHT','MD VHT','PM VHT','NT VHT'])
pct_vht_by_tod = vht_by_tod/vht_total
pct_vht_by_tod = pct_vht_by_tod.set_axis(['% AM VHT','% MD VHT','% PM VHT','% NT VHT'])
vht_by_tod = pd.concat([vht_by_tod, pd.Series({'Total VHT': vht_total}), pct_vht_by_tod])
#Insert title line
vht_by_tod = pd.concat([pd.Series({'VHT by time of day':""}),vht_by_tod])

# VHD by time of day
vhd_am=df_hwy_net_filtered['I4AMVHD'].sum()
vhd_md=df_hwy_net_filtered['I4MDVHD'].sum()
vhd_pm=df_hwy_net_filtered['I4PMVHD'].sum()
vhd_nt=df_hwy_net_filtered['I4NTVHD'].sum()
vhd_total=vhd_am+vhd_md+vhd_pm+vhd_nt
vhd_by_tod=pd.Series([vhd_am,vhd_md,vhd_pm,vhd_nt],index=['AM VHD','MD VHD','PM VHD','NT VHD'])
pct_vhd_by_tod = vhd_by_tod/vhd_total
pct_vhd_by_tod = pct_vhd_by_tod.set_axis(['% AM VHD','% MD VHD','% PM VHD','% NT VHD'])
vhd_by_tod = pd.concat([vhd_by_tod, pd.Series({'Total VHD': vhd_total}), pct_vhd_by_tod])
#Insert title line
vhd_by_tod = pd.concat([pd.Series({'VHD by time of day':""}),vhd_by_tod])

# Average speed in mph by time of day (VMT/VHT)
spd_am=vmt_am/vht_am
spd_md=vmt_md/vht_md
spd_pm=vmt_pm/vht_pm
spd_nt=vmt_nt/vht_nt
spd_24=vmt_total/vht_total
spd_by_tod=pd.Series([spd_am,spd_md,spd_pm,spd_nt,spd_24],index=['AM speed','MD speed','PM speed','NT speed','Daily average speed'])
#Insert title line
spd_by_tod = pd.concat([pd.Series({'Average speed by time of day (VMT/VHT)':""}),spd_by_tod])

# Additional region-level VMT metrics
vmt_per_capita = vmt_total/pop_total
vmt_per_hh = vmt_total/hh_total
additional_vmt_metrics=pd.Series([vmt_per_capita,vmt_per_hh],index=['VMT per Capita','VMT per household'])
#Insert title line
additional_vmt_metrics = pd.concat([pd.Series({'Additional region-level VMT metrics':""}),additional_vmt_metrics])

print("- Generating transit assignment summaries...")
### Transit Assignment Summaries

# Define modes
modes = ["DR_AB_WK","DR_BM_WK","DR_CR_WK","DR_MR_WK","KR_AB_WK","KR_BM_WK","KR_MR_WK",
         "WK_AB_DR","WK_AB_WK","WK_BM_DR","WK_BM_WK","WK_MR_DR","WK_MR_WK","WK_CR_DR",
         "WK_CR_WK","WK_AB_KR","WK_BM_KR","WK_MR_KR"]

# Define time periods
timeperiods = ["AM", "PM", "MD", "NT"]

# read all link vol DBFs and combine into one DF

linkvol_df = pd.DataFrame()

for i in timeperiods:
    for j in modes:
        filename = "i4_" + i + "_" + j + "_LINKVOL.DBF"
        dbf = Dbf5(os.path.join(scen_dir,r"outputs\trn_assign", filename))
        df = dbf.to_dataframe()

        df['period'] = i
        df['TRIP_MODE'] = j
        df['ACCESS_MODE'] = j.split("_")[0]
        df['EGRESS_MODE'] = j.split("_")[2]
        df['LINE_HAUL'] = j.split("_")[1]

        linkvol_df = pd.concat([linkvol_df,df])


# Transit boardings by line haul and access modes
df_trn_ons_by_linehaul_access = linkvol_df.groupby(['LINE_HAUL','ACCESS_MODE'])['ONA'].sum().reset_index()
trn_ons_by_linehaul_access = pd.Series(df_trn_ons_by_linehaul_access['ONA'].values,index=[
    'All Bus - PNR Access','All Bus - KNR Access','All Bus - Walk Access','Bus/Metro - PNR Access','Bus/Metro - KNR Access','Bus/Metro - Walk Access',
    'Commuter Rail - PNR/KNR Access','Commuter Rail - Walk Access','Metrorail Only - PNR Access','Metrorail Only - KNR Access','Metrorail Only - Walk Access'])
total_trn_ons=trn_ons_by_linehaul_access.sum()
trn_ons_by_linehaul_access = pd.concat([trn_ons_by_linehaul_access,pd.Series([total_trn_ons],index=['Total transit boardings'])])
#Insert title line
trn_ons_by_linehaul_access = pd.concat([pd.Series({'VII. Transit Assignment Summaries':"",'Transit boardings by line haul and access modes':""}),trn_ons_by_linehaul_access])

# Transit boardings by mode
df_trn_ons_by_mode = linkvol_df.groupby(['MODE'])['ONA'].sum().reset_index()
mtr_ons = int(df_trn_ons_by_mode.loc[df_trn_ons_by_mode['MODE'] == 3, 'ONA'].values[0])
com_ons = int(df_trn_ons_by_mode.loc[df_trn_ons_by_mode['MODE'] == 4, 'ONA'].values[0])
if(5 in df_trn_ons_by_mode['MODE'].values):
    lrt_ons = int(df_trn_ons_by_mode.loc[df_trn_ons_by_mode['MODE'] == 5, 'ONA'].values[0])
else:
    lrt_ons = 0
bus_ons = int(df_trn_ons_by_mode[(df_trn_ons_by_mode['MODE'] < 3) | (df_trn_ons_by_mode['MODE'] > 5)]['ONA'].sum())
total_trn_ons = mtr_ons+com_ons+lrt_ons+bus_ons
trn_ons_by_mode = pd.Series([mtr_ons, com_ons,lrt_ons, bus_ons], index=['Metrorail boardings','commuter rail boardings','light rail boardings','bus/streetcar/BRT boardings'])
pct_trn_ons_by_mode = trn_ons_by_mode/total_trn_ons
pct_trn_ons_by_mode = pct_trn_ons_by_mode.set_axis(['% Metrorail boardings','% commuter rail boardings','% light rail boardings','% bus/streetcar/BRT boardings'])
trn_ons_by_mode = pd.concat([trn_ons_by_mode,pd.Series([total_trn_ons],index=['Total transit boardings']),pct_trn_ons_by_mode])
#Insert title line
trn_ons_by_mode = pd.concat([pd.Series({'Transit boardings (transfers included) by mode':""}),trn_ons_by_mode])

# Metrorail station entries
# There are two methods to calculate Metrorail station entries (no transfers): One is to use the link volume files,
# the other is to use the s2s volume files. The results from the two methods are nearly identical (e.g., 506,978 vs. 506,979)
# Although the code for both methods are included below, the first method is used, as it does not require reading an
# additonal set of s2s files. It should also be noted that the total station Metrorail entries computed in this script
# is slightly different from that generated by the LINESUM access_report (e.g., 506,423).

# Method 1
mtr_station_entries = linkvol_df[(linkvol_df['MODE'] >10) & (linkvol_df['B'] >= 8000)  & (linkvol_df['B'] < 9000)]['VOL'].sum()
trn_ons_by_mode = pd.concat([trn_ons_by_mode,pd.Series({'Metrorail station entries (no transfers)':mtr_station_entries})])

"""
# Method 2
# read all S2S DBFs and combine into one DF

non_AB_modes = ["DR_BM_WK","DR_CR_WK","DR_MR_WK","KR_BM_WK","KR_MR_WK",
         "WK_BM_DR","WK_BM_WK","WK_MR_DR","WK_MR_WK","WK_CR_DR",
         "WK_CR_WK","WK_BM_KR","WK_MR_KR"]
s2s_df = pd.DataFrame()

for i in timeperiods:
    for j in non_AB_modes:
        filename = "i4_" + i + "_" + j + "_S2Svol.DBF"
        dbf = Dbf5(os.path.join(scen_dir,r"outputs\trn_assign",filename))
        df = dbf.to_dataframe()
        s2s_df = pd.concat([s2s_df,df])

mtr_station_entries = s2s_df[(s2s_df['FromNode'] >= 8000) | (s2s_df['FromNode'] < 9000)]['VOL'].sum()
trn_ons_by_mode = pd.concat([trn_ons_by_mode,pd.Series({'Metrorail station entries (no transfers)':mtr_station_entries})])

"""

# Boardings by Metrorail/commuter rail line
linkvol_df_HCT = linkvol_df[(linkvol_df['MODE'] == 3) | (linkvol_df['MODE'] == 4)]
# Remove "-" and "/" at the end of line name
linkvol_df_HCT['NAME'] = linkvol_df_HCT['NAME'].str.replace('-', '')
linkvol_df_HCT['NAME'] = linkvol_df_HCT['NAME'].str.replace('/', '')

# Group MARC/VRE/Metrorail lines
def group_lines(row):
    linename = row['NAME']

    if linename[:3] == 'MBR':
        return 'MARC/Brunswick'
    elif linename[:4] == 'MCAM':
        return 'MARC/Camden'
    elif linename[:2] == 'MP':
        return 'MARC/Penn'
    elif ((linename[:4] == 'VMAS')|( linename[:5] == 'AMTKM')):
        return 'VRE/Manassas'
    elif ((linename[:2] == 'VF')|(linename[:4] == 'AMTK')):
        return 'VRE/Fredericksburg'
    elif linename[:3] == 'WMB':
        return 'Metro/Blue Line'
    elif linename[:3] == 'WMG':
        return 'Metro/Green Line'
    elif linename[:3] == 'WMO':
        return 'Metro/Orange Line'
    elif linename[:3] == 'WMR':
        return 'Metro/Red Line'
    elif linename[:3] == 'WMS':
        return 'Metro/Silver Line'
    elif linename[:3] == 'WMY':
        return 'Metro/Yellow Line'
    else:
        return linename

new_col = linkvol_df_HCT.apply(group_lines, axis=1)
linkvol_df_HCT = linkvol_df_HCT.assign(GRPNAME=new_col.values)
ons_by_HCT_line = linkvol_df_HCT.groupby('GRPNAME')['ONA'].sum()

print(ons_by_HCT_line)

MARC_total_ons = ons_by_HCT_line[ons_by_HCT_line.index.map(lambda s: s.startswith('MARC'))].sum()
VRE_total_ons = ons_by_HCT_line[ons_by_HCT_line.index.map(lambda s: s.startswith('VRE'))].sum()
Metrorail_total_ons = ons_by_HCT_line[ons_by_HCT_line.index.map(lambda s: s.startswith('Metro'))].sum()
#Insert title line
ons_by_HCT_line = pd.concat([pd.Series({'Boardings by MARC/VRE/Metrorail line':""}),ons_by_HCT_line,pd.Series(
    {'All MARC lines':MARC_total_ons,'All VRE lines':VRE_total_ons,'All Metrorail lines':Metrorail_total_ons})])


### Concatenate piecemeal Series into one big Series for each scenario
scen_data=pd.concat([scen_info,totals,emp,pertypeDistbn,hhSizeDist,hhIncomeDist,autoOwnership,wfh,telecommuteFrequency,mandTourLengths,dapSummary,
                     mtfSummary,tour_rate_by_pertype,inmSummary,jtours_by_jointComp,nonMandTourLengths,todProfile_dep,todProfile_arr,tmodeProfile,tmodeProfile_work,
                     stopfreqDir_out,stopfreqDir_in,stopfreq_total,stoppurpose,ood_dist_by_purp,stopTripDep_sdep,stopTripDep_tdep,tripModeProfile,tripModeProfile_wt,
                     #vmt_by_ft,vmt_by_tod,vht_by_tod,vhd_by_tod,spd_by_tod,additional_vmt_metrics])
                     external_trips,vmt_by_ft,vmt_by_tod,vht_by_tod,vhd_by_tod,spd_by_tod,additional_vmt_metrics,
                     trn_ons_by_linehaul_access,trn_ons_by_mode,ons_by_HCT_line])

#Merge the scenario Series data into the final dataframe
df_vfs=pd.DataFrame({'Item': scen_data.index, 'Scen1': scen_data.values})
df_vfs.set_index('Item')


### Format final outputs
# Find the index for Tour rate by person type
a = df_vfs.index[df_vfs['Item'] == 'Tour rate by person type (active persons only)'].tolist()[0]
# Find the index for Average Non-Mandatory tour lengths (Miles)
b = df_vfs.index[df_vfs['Item'] == 'Average Non-Mandatory tour lengths (Miles)'].tolist()[0]
# Find the index for Aver. out-of-direction dist. by tour purpose
c = df_vfs.index[df_vfs['Item'] == 'Aver. out-of-direction dist. by tour purpose'].tolist()[0]

def format_row(indx,values,row_index):
    global a,b,c
    itm=values[0]
    values_fmt = []

    for elem in values:
        try:
            if '%' in itm:
                values_fmt.append('{:,.1f}%'.format(elem*100))
            elif (('per_' in itm) | ('per ' in itm) | ('speed' in itm) | ('distance' in itm) | ('length' in itm) |
                  (row_index in range(a+1,a+9)) | (row_index in range(b+1,b+8)) | (row_index in range(c+1,c+10))):
                values_fmt.append("{:,.2f}".format(float(elem)))
            else:
                values_fmt.append("{:,}".format(int(elem)))
        except:
            values_fmt.append(elem)


    return pd.Series(values_fmt,index=indx)

df_vfs=df_vfs.apply(lambda x: format_row(x.index,x.values,x.name), axis=1)
#df_vfs=df_vfs.applyapplymap('{:,.2f}'.format)

print(df_vfs.to_string())

df_vfs.to_csv(os.path.join(scen_dir, "outputs", "reports", "View_from_Space_Summary_Gen3.csv"), index=True)
