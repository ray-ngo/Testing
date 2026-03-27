import psutil
import os

# This is the threshold in GB
DISK_SPACE_THRESHOLD = 500

# Don't change anything below this
free_space = psutil.disk_usage(os.environ['SCEN_DIRECTORY']).free

if free_space / 1024.0 / 1024.0 / 1024.0 < DISK_SPACE_THRESHOLD:
    exit(-1)
else:
    exit(0)
