;******************************************************************
;**  LOS'E' Capacities and Freeflow Speeds Assumptions:          **
;******************************************************************
;Run 22
;            areatp > 1    2    3    4    5     6   fac type
;                    ---  ---  ---  ---  ---   ---     V
SPDCAP CAPACITY[01]=3150 3150 3150 3150 3150  3150  ; cen
SPDCAP CAPACITY[11]=1900 1900 2000 2000 2000  2000 ; fwy
SPDCAP CAPACITY[21]= 600  800  960  960 1100  1100  ; maj
SPDCAP CAPACITY[31]= 500  600  700  840  900   900  ; min
SPDCAP CAPACITY[41]= 500  500  600  800  800   800  ; col
SPDCAP CAPACITY[51]=1100 1200 1200 1400 1600  1600  ; xwy
SPDCAP CAPACITY[61]=1000 1000 1000 1000 2000  2000  ; rmp
;
;  initial speed values :
;
;            areatp > 1    2    3    4    5    6   fac type
;                    ---  ---  ---  ---  ---  ----    V
SPDCAP    SPEED[01]= 17   17   23   29   35   40    ; cen
SPDCAP    SPEED[11]= 63   63   69   69   75   75    ; fwy
SPDCAP    SPEED[21]= 40   40   52   52   58   58    ; maj
SPDCAP    SPEED[31]= 40   40   46   46   46   52    ; min
SPDCAP    SPEED[41]= 35   35   35   40   40   40    ; col
SPDCAP    SPEED[51]= 52   52   58   58   58   63    ; xwy
SPDCAP    SPEED[61]= 23   23   35   35   40   58    ; rmp
