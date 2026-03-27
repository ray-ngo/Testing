# ActivitySim
# See full license in LICENSE.txt.

import sys
import argparse
import warnings
import logging

# Disable future warnings
warnings.simplefilter(action='ignore', category=FutureWarning)

from activitysim.cli.run import add_run_args, run

import extensions

# Define log filter
class LevelFilter(logging.Filter):
    def __init__(self, levels=None):
        super().__init__()
        self.levels = set(levels or [])

    def filter(self, record):
        return record.levelno in self.levels


# MAIN
if __name__ == '__main__':

    parser = argparse.ArgumentParser()
    add_run_args(parser)
    args = parser.parse_args()

    sys.exit(run(args))
