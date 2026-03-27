# -*- coding: utf-8 -*-
"""
Created on Sept 2, 2022

This script is created to summarize person trips from ActivitySim into trip matrices by tour primary purpose
and by trip mode at the TAZ levels.

@author: fxie
"""

# ***** Import Libraries  ******
import sys
import os
import numpy as np
import openmatrix as omx
import pandas as pd

# ***** Initial Setup ******

# Read the path to the model run of interest from the main batch file
scen_dir = os.environ.get('SCEN_DIRECTORY')


print ("Summarizing the trip data from " + scen_dir + "...")

# ***** Read Inputs ******

# read the final trip table, final household table, final tour table and final land use table from ActivitySim

"""
final_trips.csv
Note *: trip_num and trip_count indicate sequence number and total number of trips on a tour
trip_id,person_id,household_id,primary_purpose,trip_num,outbound,trip_count,destination,origin,tour_id,purpose,destination_logsum,depart,trip_mode,mode_choice_logsum

final_households.csv

household_id,puma_geoid,home_zone_id,TYPE,hhsize,auto_ownership,HHT,hhincadj,workers,has_children,sample_rate,income,income_in_thousands,income_segment,
median_value_of_time,hh_value_of_time,num_workers,num_non_workers,num_drivers,num_adults,num_children,num_young_children,num_children_5_to_15,num_children_6_to_12,
num_children_16_to_17,num_college_age,num_young_adults,non_family,family,home_is_urban,home_is_rural,TAZ,num_predrive_child,num_nonworker_adults,num_fullTime_workers,
num_partTime_workers,retired_adults_only_hh,hh_work_auto_savings_ratio,num_under16_not_at_school,num_travel_active,num_travel_active_adults,num_travel_active_preschoolers,
num_travel_active_children,num_travel_active_non_preschoolers,participates_in_jtf_model,joint_tour_frequency,num_hh_joint_tours

"""
trips_df = pd.read_csv(scen_dir + "/outputs/activitysim/final_trips.csv", usecols=['origin', 'destination', 'household_id','tour_id','primary_purpose', 'trip_mode'], dtype={'origin':'int32', 'destination':'int32', 'household_id':'int64','tour_id':'int64', 'primary_purpose':'str', 'trip_mode':'str'})
# trips_df = pd.read_csv(scen_dir + "/outputs/activitysim/final_trips.csv", usecols=['origin', 'destination', 'household_id','tour_id','purpose', 'trip_mode'])

pd.set_option('display.max_columns', None)
pd.set_option('display.max_rows', None)

# Print out column names in the trip file
# for col in trips_df.columns:
#    print(col)

hh_df = pd.read_csv(scen_dir + "/outputs/activitysim/final_households.csv", usecols=['household_id','sample_rate'], index_col='household_id')

tour_df = pd.read_csv(scen_dir + "/outputs/activitysim/final_tours.csv", usecols=['tour_id','tour_category','number_of_participants'], index_col='tour_id')

taz_df = pd.read_csv(scen_dir + "/outputs/activitysim/final_land_use.csv", usecols=['zone_id'],index_col='zone_id')
if not taz_df.index.is_monotonic_increasing:
    taz_df = taz_df.sort_index()

# Extract the sample rate and number of participants for each trip through mapping
# Note: Sample rate has been accounted for in the final trip/person/hh files, so it is set as 1.0

# household_weights = hh_df['sample_rate']
trips_df['sample_rate'] = 1.0

tour_participants=tour_df['number_of_participants']
trips_df['tour_participants'] = trips_df.tour_id.map(tour_participants)
tour_category=tour_df['tour_category']
trips_df['tour_category'] = trips_df.tour_id.map(tour_category)

# Consistent with Summarize_ActivitySim_MWCOG.R, number of persons on a joint tour is equal to number of tour participants
trips_df['persons_on_trip'] = np.where(trips_df['tour_category']=='joint',trips_df['tour_participants']/trips_df['sample_rate'],1/trips_df['sample_rate'])
print("Total Number of Trip Records: " + str(len(trips_df)))
print("Total Number of Person Trips: " + str(trips_df['persons_on_trip'].sum()))

print("First 20 rows of the Trip Table:")
print(trips_df.head(20))

print(trips_df['persons_on_trip'].unique())
tour_purp_uniq = ['work', 'univ', 'school', 'escort', 'shopping', 'othmaint', 'eatout', 'social', 'othdiscr',
                  'atwork','all_purp']
trip_mode_uniq = ['DRIVEALONE', 'SHARED2', 'SHARED3', 'WALK', 'BIKE', 'WALK_AB', 'WALK_BM', 'WALK_MR', 'WALK_CR',
                     'PNR_AB', 'PNR_BM', 'PNR_MR', 'PNR_CR', 'KNR_AB', 'KNR_BM', 'KNR_MR', 'SCHOOLBUS',
                     'TAXI', 'TNC', 'ALL_MODE']

trip_subtotals_df = pd.DataFrame({'tour_purpose': np.repeat(tour_purp_uniq, len(trip_mode_uniq)),
                   'trip_mode':np.tile(trip_mode_uniq, len(tour_purp_uniq))}, columns=['tour_purpose','trip_mode'])
trip_subtotals_df ['trips'] = 0
trip_subtotals_df ['shares'] = 0.0

# print(trips_df['tour_participants'].value_counts())
# print(trips_df['sample_rate'].value_counts())

# ***** Define Function ******
# The write_matrices function below is a rewrite based on the same function defined in the ActivitySim code.
# For instance, refer to Z:\ModelRuns\fy22\activitysim\activitysim\abm\models\trip_matrices.py.
def write_matrices(
    aggregate_trips, zone_index, orig_index, dest_index
):
    """
    Write aggregated trips to OMX format.

    The MATRICES setting lists the new OMX files to write.
    Each file can contain any number of 'tables', each corresponding
    to .

    Any data type may be used for columns added in the annotation phase,
    but the table 'data_field's must be summable types: ints, floats, bools.
    """

    for purp in ['work', 'univ', 'school', 'escort', 'shopping', 'othmaint', 'eatout', 'social', 'othdiscr','atwork','all_purp']:
        filename = 'final_trips_' + purp + '.omx'
        file = omx.open_file(scen_dir + "/outputs/hwy_assign/"+ filename, "w")  # possibly overwrite existing file

        for mode in ['DRIVEALONE', 'SHARED2', 'SHARED3', 'WALK', 'BIKE', 'WALK_AB', 'WALK_BM', 'WALK_MR', 'WALK_CR',
                     'PNR_AB', 'PNR_BM', 'PNR_MR', 'PNR_CR', 'KNR_AB', 'KNR_BM', 'KNR_MR', 'SCHOOLBUS',
                     'TAXI', 'TNC', 'ALL_MODE']:
            col = purp + '_' + mode

            if col not in aggregate_trips:
                print(f"missing {col} column in aggregate_trips DataFrame")
                return

            # print(aggregate_trips[col].sum())

            aggregate_trips[col] = (
                aggregate_trips[col] / aggregate_trips['sample_rate']
            )

            data = np.zeros((len(zone_index), len(zone_index)))
            data[orig_index, dest_index] = aggregate_trips[col]

            subtotal=aggregate_trips[col].sum()
            print(
                "writing %s, subtotal= %0.0f" % (col, subtotal)
            )
            """
            trip_subtotals_df.trips[(trip_subtotals_df['tour_purpose'] == purp) & (trip_subtotals_df['trip_mode'] == mode)]=subtotal

            trip_subtotals_df.trips[(trip_subtotals_df['tour_purpose'] == purp) & (trip_subtotals_df['trip_mode'] =='all_mode')] += subtotal
            trip_subtotals_df.trips[(trip_subtotals_df['tour_purpose'] == 'all_purp') & (trip_subtotals_df['trip_mode'] ==mode)] += subtotal
            trip_subtotals_df.trips[(trip_subtotals_df['tour_purpose'] == 'all_purp') & (trip_subtotals_df['trip_mode'] =='all_mode')] += subtotal
            """
            trip_subtotals_df.loc[(trip_subtotals_df['tour_purpose'] == purp) & (trip_subtotals_df['trip_mode'] == mode), 'trips']=subtotal

            file[mode] = data  # write to file

        # include the index-to-zone map in the file
        print(
            "adding %s mapping for %s zones to %s"
            % (zone_index.name, zone_index.size, filename)
        )
        file.create_mapping(zone_index.name, zone_index.to_numpy())

        print("closing %s" % filename)
        file.close()


# ***** Write Trip Tables by Purpose and Mode into OMX Files ******
# The code below is a rewrite of a similar ActivitySim code.
# For instance, refer to Z:\ModelRuns\fy22\activitysim\activitysim\abm\models\trip_matrices.py and Z:\ModelRuns\fy22\Gen3_Model_Runs\source\configs\activitysim\configs\write_trip_matrices.yaml
"""
Trip Primary Purposes (tour purpose):
'work', 'univ', 'school', 'escort', 'shopping', 'othmaint', 'eatout', 'social', 'othdiscr','atwork'

Trip Modes:
'DRIVEALONE','SHARED2','SHARED3','WALK','BIKE','WALK_AB','WALK_BM','WALK_MR','WALK_CR','PNR_AB','PNR_BM','PNR_MR','PNR_CR','KNR_AB','KNR_BM','KNR_MR','KNR_CR','SCHOOLBUS','TAXI','TNC_SINGLE','TNC_SHARED'

"""
new_columns = {}

"""
    Note: The new_columns is created because the following syntax leads to a PerformanceWarning: DataFrame is highly fragmented. This is usually the result of calling `frame.insert` many times, which has poor performance.

    trips_df[purp + '_DRIVEALONE'] = ((trips_df.primary_purpose == purp) & (trips_df.trip_mode == 'DRIVEALONE')) * trips_df.tour_participants
    trips_df[purp + '_SHARED2'] = ((trips_df.primary_purpose == purp) & (trips_df.trip_mode == 'SHARED2')) * trips_df.tour_participants
    ...
    trips_df[purp + '_TNC'] = ((trips_df.primary_purpose == purp) & (trips_df.trip_mode.isin(['TNC_SINGLE', 'TNC_SHARED']))) * trips_df.tour_participants
"""

for purp in ['work', 'univ', 'school', 'escort', 'shopping', 'othmaint', 'eatout', 'social', 'othdiscr','atwork']:
    new_columns[f"{purp}_DRIVEALONE"] = ((trips_df.primary_purpose == purp) & (trips_df.trip_mode == 'DRIVEALONE')) * trips_df.persons_on_trip
    new_columns[f"{purp}_SHARED2"] = ((trips_df.primary_purpose == purp) & (trips_df.trip_mode == 'SHARED2')) * trips_df.persons_on_trip
    new_columns[f"{purp}_SHARED3"] = ((trips_df.primary_purpose == purp) & (trips_df.trip_mode == 'SHARED3')) * trips_df.persons_on_trip
    new_columns[f"{purp}_WALK"] = ((trips_df.primary_purpose == purp) & (trips_df.trip_mode == 'WALK')) * trips_df.persons_on_trip
    new_columns[f"{purp}_BIKE"] = ((trips_df.primary_purpose == purp) & (trips_df.trip_mode == 'BIKE')) * trips_df.persons_on_trip
    new_columns[f"{purp}_WALK_AB"] = ((trips_df.primary_purpose == purp) & (trips_df.trip_mode == 'WALK_AB')) * trips_df.persons_on_trip
    new_columns[f"{purp}_WALK_BM"] = ((trips_df.primary_purpose == purp) & (trips_df.trip_mode == 'WALK_BM')) * trips_df.persons_on_trip
    new_columns[f"{purp}_WALK_MR"] = ((trips_df.primary_purpose == purp) & (trips_df.trip_mode == 'WALK_MR')) * trips_df.persons_on_trip
    new_columns[f"{purp}_WALK_CR"] = ((trips_df.primary_purpose == purp) & (trips_df.trip_mode == 'WALK_CR')) * trips_df.persons_on_trip
    new_columns[f"{purp}_PNR_AB"] = ((trips_df.primary_purpose == purp) & (trips_df.trip_mode == 'PNR_AB')) * trips_df.persons_on_trip
    new_columns[f"{purp}_PNR_BM"] = ((trips_df.primary_purpose == purp) & (trips_df.trip_mode == 'PNR_BM')) * trips_df.persons_on_trip
    new_columns[f"{purp}_PNR_MR"] = ((trips_df.primary_purpose == purp) & (trips_df.trip_mode == 'PNR_MR')) * trips_df.persons_on_trip
    new_columns[f"{purp}_PNR_CR"] = ((trips_df.primary_purpose == purp) & (trips_df.trip_mode.isin(['PNR_CR', 'KNR_CR']))) * trips_df.persons_on_trip
    new_columns[f"{purp}_KNR_AB"] = ((trips_df.primary_purpose == purp) & (trips_df.trip_mode == 'KNR_AB')) * trips_df.persons_on_trip
    new_columns[f"{purp}_KNR_BM"] = ((trips_df.primary_purpose == purp) & (trips_df.trip_mode == 'KNR_BM')) * trips_df.persons_on_trip
    new_columns[f"{purp}_KNR_MR"] = ((trips_df.primary_purpose == purp) & (trips_df.trip_mode == 'KNR_MR')) * trips_df.persons_on_trip
    new_columns[f"{purp}_SCHOOLBUS"] = ((trips_df.primary_purpose == purp) & (trips_df.trip_mode == 'SCHOOLBUS')) * trips_df.persons_on_trip
    new_columns[f"{purp}_TAXI"] = ((trips_df.primary_purpose == purp) & (trips_df.trip_mode == 'TAXI')) * trips_df.persons_on_trip
    new_columns[f"{purp}_TNC"] = ((trips_df.primary_purpose == purp) & (trips_df.trip_mode.isin(['TNC_SINGLE', 'TNC_SHARED']))) * trips_df.persons_on_trip
    new_columns[f"{purp}_ALL_MODE"] = (trips_df.primary_purpose == purp) * trips_df.persons_on_trip

new_columns["all_purp_DRIVEALONE"] = (trips_df.trip_mode == 'DRIVEALONE') * trips_df.persons_on_trip
new_columns["all_purp_SHARED2"] = (trips_df.trip_mode == 'SHARED2') * trips_df.persons_on_trip
new_columns["all_purp_SHARED3"] = (trips_df.trip_mode == 'SHARED3') * trips_df.persons_on_trip
new_columns["all_purp_WALK"] = (trips_df.trip_mode == 'WALK') * trips_df.persons_on_trip
new_columns["all_purp_BIKE"] = (trips_df.trip_mode == 'BIKE') * trips_df.persons_on_trip
new_columns["all_purp_WALK_AB"] = (trips_df.trip_mode == 'WALK_AB') * trips_df.persons_on_trip
new_columns["all_purp_WALK_BM"] = (trips_df.trip_mode == 'WALK_BM') * trips_df.persons_on_trip
new_columns["all_purp_WALK_MR"] = (trips_df.trip_mode == 'WALK_MR') * trips_df.persons_on_trip
new_columns["all_purp_WALK_CR"] = (trips_df.trip_mode == 'WALK_CR') * trips_df.persons_on_trip
new_columns["all_purp_PNR_AB"] = (trips_df.trip_mode == 'PNR_AB') * trips_df.persons_on_trip
new_columns["all_purp_PNR_BM"] = (trips_df.trip_mode == 'PNR_BM') * trips_df.persons_on_trip
new_columns["all_purp_PNR_MR"] = (trips_df.trip_mode == 'PNR_MR') * trips_df.persons_on_trip
new_columns["all_purp_PNR_CR"] = (trips_df.trip_mode.isin(['PNR_CR', 'KNR_CR'])) * trips_df.persons_on_trip
new_columns["all_purp_KNR_AB"] = (trips_df.trip_mode == 'KNR_AB') * trips_df.persons_on_trip
new_columns["all_purp_KNR_BM"] = (trips_df.trip_mode == 'KNR_BM') * trips_df.persons_on_trip
new_columns["all_purp_KNR_MR"] = (trips_df.trip_mode == 'KNR_MR') * trips_df.persons_on_trip
new_columns["all_purp_SCHOOLBUS"] = (trips_df.trip_mode == 'SCHOOLBUS') * trips_df.persons_on_trip
new_columns["all_purp_TAXI"] = (trips_df.trip_mode == 'TAXI') * trips_df.persons_on_trip
new_columns["all_purp_TNC"] = (trips_df.trip_mode.isin(['TNC_SINGLE', 'TNC_SHARED'])) * trips_df.persons_on_trip
new_columns["all_purp_ALL_MODE"] = trips_df.persons_on_trip

new_columns = pd.DataFrame(new_columns, index=trips_df.index)

trips_df = pd.concat([trips_df, new_columns], axis=1)

# print("First 20 rows of the Trip Table with new columns:")
# print(trips_df.head(20))

# Group trip records by origin and destination TAZs
aggregate_trips = trips_df.groupby(["origin", "destination"], sort=False).sum(numeric_only=True)

print("Total Number of Person Trips after aggregation: " + str(aggregate_trips['persons_on_trip'].sum()))
# print("First 20 rows of the aggregated Trip Table:")
# print(aggregate_trips.head(20))

# use the average household weight for all trips in the origin destination pair
aggregate_weight = (
    trips_df[["origin", "destination", "sample_rate"]]
        .groupby(["origin", "destination"], sort=False)
        .mean()
)
aggregate_trips['sample_rate'] = aggregate_weight['sample_rate']

orig_vals = aggregate_trips.index.get_level_values("origin")
dest_vals = aggregate_trips.index.get_level_values("destination")

# use the land use table for the set of possible tazs
zone_index = taz_df.index
assert all(zone in zone_index for zone in orig_vals)
assert all(zone in zone_index for zone in dest_vals)

_, orig_index = zone_index.reindex(orig_vals)
_, dest_index = zone_index.reindex(dest_vals)

write_matrices(
    aggregate_trips, zone_index, orig_index, dest_index
)

for purp in ['work', 'univ', 'school', 'escort', 'shopping', 'othmaint', 'eatout', 'social', 'othdiscr','atwork','all_purp']:
    for mode in ['DRIVEALONE', 'SHARED2', 'SHARED3', 'WALK', 'BIKE', 'WALK_AB', 'WALK_BM', 'WALK_MR', 'WALK_CR',
                 'PNR_AB', 'PNR_BM', 'PNR_MR', 'PNR_CR', 'KNR_AB', 'KNR_BM', 'KNR_MR', 'SCHOOLBUS',
                 'TAXI', 'TNC','ALL_MODE']:

        tmp_trips=trip_subtotals_df.loc[(trip_subtotals_df['tour_purpose'] == purp) & (
                trip_subtotals_df['trip_mode'] == mode), 'trips'].values

        tmp_tot_trips=trip_subtotals_df.loc[(trip_subtotals_df['tour_purpose'] == purp) & (trip_subtotals_df['trip_mode'] == "ALL_MODE"), 'trips'].values

        print(tmp_trips)
        print(tmp_tot_trips)

        trip_subtotals_df.loc[
            (trip_subtotals_df['tour_purpose'] == purp) & (trip_subtotals_df['trip_mode'] == mode), 'shares']=tmp_trips/tmp_tot_trips

trip_subtotals_df.shares = trip_subtotals_df.shares.mul(100).astype(str).add('%')
#print(trip_subtotals_df)


trip_subtotals_df.to_csv(scen_dir + '/outputs/hwy_assign/person_trips_by_tour_purp_and_trip_mode.csv', index=False)


#print("Converting omx trip tables to Cube Format...")
#subprocess.run(["Voyager.exe","convert_trip_tables_omx_to_trp.s -Pvoya -S..\\"])

print("The Python script is executed successfully!")
