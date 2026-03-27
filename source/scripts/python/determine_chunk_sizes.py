"""
Dynamic chunker - Gen3 Model
author: glang
version: 1.0.3

Dynamically determines the explicit chunk size (fraction) based on the number of sample
households. From 750k onwards, will use 2.7M households (2018 baseline) and the chunks
to determine the chunk size. These have been determined using 2018 and 2050.

NOTE: Due to the nature of the chunking precision (:.2f), a maximum of 10M households
should not be exceeded. In this case, the rounding precision should be increased to 3.
"""

from decimal import Decimal, ROUND_HALF_UP
import os
import re
import sys

import numpy as np
import pandas as pd

# Base divisor and filename list (in alphabetical order)
CHUNK_DIVISOR = {
    "atwork_subtour_destination.yaml": 2_100_000,
    "mandatory_tour_scheduling.yaml": 480_000,
    "non_mandatory_tour_destination.yaml": 540_000,
    "non_mandatory_tour_frequency.yaml": 540_000,
    "school_location.yaml": 3_200_000,
    "trip_destination.yaml": 600_000,
    "vehicle_type_choice.yaml": 540_000,
    "workplace_location.yaml": 425_000,
}

# Base setting for number of processes (cpu) and ram (GB) used for activitysim to which
# the chunks are tuned. BASE_CPU is currently not in use, as it was found that the
# number of CPUs does not have a significant impact on RAM usage. However, it is here
# for purpose of documentation, as this was the setting used to develop the chunk
# divisor list.
BASE_CPU = 20
BASE_RAM = 200

########################################################################################
### FUNCTION                                                                         ###
########################################################################################
def round_half_up(x: float) -> int:
    """
    Rounds half up.
    Pythons 'round' function uses banker's rounding (https://en.wikipedia.org/
    wiki/Rounding#Rounding_half_away_from_zero).
    """
    return int(Decimal(x).quantize(Decimal('1.'), rounding=ROUND_HALF_UP))


def pceil(x: float, precision=2):
    """
    Ceils a float to the given precision.
    """
    return np.true_divide(np.ceil(x * 10**precision), 10**precision)


########################################################################################
### MAIN                                                                             ###
########################################################################################
if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: python sript.py <households> <popsyn_directory> <config_dir>")
        sys.exit(1)

    # Get command line arguments
    n_households = int(sys.argv[1])
    popsyn = sys.argv[2]
    configs = sys.argv[3]

    # Get asim cpu and ram settings
    cfg_cpu = int(os.getenv("ASIM_NUM_PROCESSES", 0))
    cfg_ram = int(os.getenv("ASIM_RAM_AVAILABLE", 0)) / 1e9

    ## Check for valid/existing input
    if cfg_cpu == 0 or cfg_ram == 0:
        print("Invalid number of cpus or RAM set")
        sys.exit(1)

    ## Determine chunk number factor
    nfac = (BASE_RAM / cfg_ram)

    # If number of households passed is 0, need to get the number from synthesized hhs
    if n_households == 0:
        # Load households popsyn and get number of households
        df = pd.read_csv(fr"{popsyn}\combined_synthetic_hh.csv", usecols=["household_id"])
        n_households = df.size

    # Determine number of chunks and corresponding fractions
    chunks = {k: round_half_up((n_households / v) * nfac) for k, v in CHUNK_DIVISOR.items()}
    chunks = {
        k: (x ,f"{pceil(1/x):.2f}") if x > 0 else (x, "1.00") for k, x in chunks.items()
    }

    # Write out the chunk fractions to the config files
    for fname, v in chunks.items():
        file_name = fr"{configs}\{fname}"
        try:
            with open(file_name, 'r') as file:
                file_data = file.read()
        except FileNotFoundError:
            print(fr"Error: File '{file_name}' not found.")
            sys.exit(1)

        if v[1] == "1.00":
            chunk_setting = "#explicit_chunk: 1.00"
        else:
            chunk_setting = f"explicit_chunk: {v[1]}"

        file_data = re.sub(
            r"#?explicit\_chunk:.+",
            chunk_setting,
            file_data
        )

        with open(file_name, 'w') as file:
            file.write(file_data)
