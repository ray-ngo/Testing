"""
Hardware settings - Gen3 Model
author: glang
version: 1.0.3

Utility to determine how much RAM and logical cores are available and modifying certain
variables if necessary. This utility will also throw an error if the hardware
requirements are not met (minimum of 16 cores for parallel processing and 206 GB RAM).
"""

from math import floor
import os
import sys

import psutil

########################################################################################
### CONSTANTS                                                                        ###
########################################################################################
MIN_PHYSICAL_CPU = 16
MIN_PHYSICAL_RAM = 206
DEF_ASIM_CPU = 20

RAM_RATIO = 0.8
CPU_RATIO = 0.65

CUBE_CLUSTER_INCREMENT = 16
MAX_CUBE_CLUSTER_FACTOR = 2

TOD_PERIODS = ["AM", "MD", "PM", "NT"]

BASE_SETTINGS = {"AM": 7, "MD": 2, "PM": 6, "NT": 1}

########################################################################################
### FUNCTIONS                                                                        ###
########################################################################################
def print_error(*messages):
    print("===================================================================")
    print("=                              ERROR                              =")
    for message in messages:
        print(message)
    print("Exiting model run.")
    print("===================================================================")


def to_int(val: str) -> int:
    """Safe cast to int."""
    try:
        return int(val)
    except ValueError as e:
        print_error(f"Invalid parameter {val} passed.")
        sys.exit(1)


########################################################################################
### MAIN                                                                             ###
########################################################################################
if __name__ == "__main__":

    # Get information on computer specs
    available_cpu = os.cpu_count()
    available_ram = psutil.virtual_memory().total / (1_073_741_824)

    # Error out if computer specs are insufficient
    if available_cpu < MIN_PHYSICAL_CPU:
        print_error(f"Insufficient logical cores: {available_cpu} (minimum is {MIN_PHYSICAL_CPU})")
        if available_ram < MIN_PHYSICAL_RAM:
            print_error(f"Insufficient RAM: {available_ram:.2f} GB (minimum is {MIN_PHYSICAL_RAM} GB)")
        sys.exit(1)

    if available_ram < MIN_PHYSICAL_RAM:
        print_error(f"Insufficient RAM: {available_ram:.2f} GB (minimum is {MIN_PHYSICAL_RAM} GB)")
        sys.exit(1)

    # Get env tmp file
    env_tmp_file = os.getenv("ENV_TMP_FILE", "")

    if env_tmp_file == "":
        print_error("Invalid temp file for setting ActivitySim settings.",
                    "Please check that the 'ENV_TMP_FILE' environment variable is set",
                    " to 'env_temp_file.txt' in 'run_Model.bat' (line 252)."
        )
        sys.exit(1)

    # Get cube version
    cube_version = os.getenv("cubeversion", "")
    if cube_version not in ["6.5.1", "25.00.01"]:
        print_error("Invalid cube version set.")
        sys.exit(1)

    # Get RAM setting for ActivitySim
    asim_ram = floor(available_ram * RAM_RATIO * 0.2) * 5

    # Get CPU setting for ActivitySim
    asim_cpu = min(available_cpu, max(DEF_ASIM_CPU, floor(CPU_RATIO * available_cpu * 0.5) * 2))

    # Get core factor for CUBE Cluster
    cluster_factor = floor(available_cpu / CUBE_CLUSTER_INCREMENT)

    # Write out settings for batch file
    with open(env_tmp_file, "w") as f:
        f.write(f"ASIM_NUM_PROCESSES={int(asim_cpu)}\n")
        f.write(f"ASIM_RAM_AVAILABLE={int(asim_ram * 1e9)}\n")

        if cluster_factor >= 2:
            print("Updating CUBE Cluster settings.")
            half = int(MAX_CUBE_CLUSTER_FACTOR * CUBE_CLUSTER_INCREMENT / 2)
            full = int(MAX_CUBE_CLUSTER_FACTOR * CUBE_CLUSTER_INCREMENT)
            if cube_version == "6.5.1":
                for tod in TOD_PERIODS:
                    f.write(f"{tod}subnode=1-{int(BASE_SETTINGS[tod] * MAX_CUBE_CLUSTER_FACTOR)}\n")

                f.write(f"TSsubnode=1-{half}\n")
                f.write(f"TSMDsubnode=1-{full}\n")

            else:
                for tod in TOD_PERIODS:
                    f.write(f"{tod}ClusterProcesses={int(BASE_SETTINGS[tod] * MAX_CUBE_CLUSTER_FACTOR)}\n")

                f.write(f"TotalClusterProcesses={full}\n")
                f.write(f"TSClusterProcesses={half}\n")
                f.write(f"TSMDClusterProcesses={full}\n")
