;---------------------------------------------------------------------------
;PT_asgn_AB.s
;TPB Version 2.3 travel model on the 3,722-TAZ area system
;                        - PATHSTYLE changed from 1 to 0 on 3.9.04 (RM)
;                        - iteration (_iter_) global variables used
;Assign Transit Trips by Time Period and Access Mode
; Input Files:
;  Cube Voyager Highway Network = ZONEHWY.NET
;  Transit Line Files           = MODE[1-10][AM|OP].TB
;  Transit Network Data         = MET_*.TB, COM_*.TB, BUS_*.TB
;  Walk and Drive Access        = WALKACC.TB, *_PNR_pp.TB
;  Walk Sidewalk Network        = SIDEWALK.ASC
;  Transit Trip Tables          = '%_iter_%_AMMS.TRP', '%_iter_%_OPMS.TRP'
; Output Files:
;  Transit Assignment Link and Node Files
;
; Step 1: AM Peak Walk Assignment
;  Input Files: ZONEHWY.NET, MODE?_AM.TB, *.TB, '%_iter_%_AMMS.TRP'
;  Output Files: WKBMAMnode.dbf; WKBMAMlink.dbf
; Step 2: AM Peak Drive Assignment
;  Input Files: ZONEHWY.NET, MODE?_AM.TB, *.TB, '%_iter_%_AMMS.TRP'
;  Output Files: DRBMAMnode.dbf; DRBMAMlink.dbf
; Step 3: AM Peak K/R Assignment
;  Input Files: ZONEHWY.NET, MODE?_AM.TB, *.TB, '%_iter_%_AMMS.TRP'
;  Output Files: KRBMAMnode.dbf; KRBMAMlink.dbf
; Step 4: Off Peak Walk Assignment
;  Input Files: ZONEHWY.NET, MODE?_OP.TB, *.TB, '%_iter_%_OPMS.TRP'
;  Output Files: WKBMOPnode.dbf; WKBMOPlink.dbf
; Step 5: Off Peak Drive Assignment
;  Input Files: ZONEHWY.NET, MODE?_OP.TB, *.TB, '%_iter_%_OPMS.TRP'
;  Output Files: DRBMOPnode.dbf; DRBMOPlink.dbf
; Step 6: Off Peak K/R Assignment
;  Input Files: ZONEHWY.NET, MODE?_OP.TB, *.TB, '%_iter_%_OPMS.TRP'
;  Output Files: KRBMOPnode.dbf; KRBMOPlink.dbf
;---------------------------------------------------------------------------

;  Read in time factors to increase local bus times
;  based on increasing arterial hwy congestion

pageheight=32767  ; Preclude header breaks

;---------------------------------------------------------------------------
; Loop through each period and access mode
;---------------------------------------------------------------------------
SCEN_DIRECTORY='%SCEN_DIRECTORY%'

LOOP PERIOD = 1, 4

 IF (PERIOD = 1)
  TIME_PERIOD = 'AM'
  COMBINE = 5.0
  MATIN='%SCEN_DIRECTORY%\outputs\trn_assign\%_iter_%_AMMS_all.TRP'
  AM=' '
  MD=';'
  PM=';'
  NT=';'

 ELSEIF (PERIOD = 2)
  TIME_PERIOD = 'MD'
  COMBINE = 10.0
  MATIN='%SCEN_DIRECTORY%\outputs\trn_assign\%_iter_%_MDMS_all.TRP'
  AM=';'
  MD=' '
  PM=';'
  NT=';'

 ELSEIF (PERIOD = 3)
  TIME_PERIOD = 'PM'
  COMBINE = 5.0
  MATIN='%SCEN_DIRECTORY%\outputs\trn_assign\%_iter_%_PMMS_all.TRP'
  AM=';'
  MD=';'
  PM=' '
  NT=';'

 ELSE
  TIME_PERIOD = 'NT'
  COMBINE = 10.0
  MATIN='%SCEN_DIRECTORY%\outputs\trn_assign\%_iter_%_NTMS_all.TRP'
  AM=';'
  MD=';'
  PM=';'
  NT=' '
 ENDIF

;---- start the access mode loop ----

LOOP ACCESS = 1,5

  IF (ACCESS = 1)
   ACCESS_MODE = 'WK'
   EGRESS_MODE = 'WK'
   WALK_MODEL = ' '
   DRIVE_MODEL = ';'
   KR_MODEL = ';'
   TABIN = 'MI.1.15'
  ELSEIF (ACCESS = 2)
   ACCESS_MODE = 'DR'
   EGRESS_MODE = 'WK'
   WALK_MODEL = ';'
   DRIVE_MODEL = ' '
   KR_MODEL = ';'
   TABIN = 'MI.1.11'
  ELSEIF (ACCESS = 3)
   ACCESS_MODE = 'WK'
   EGRESS_MODE = 'DR'
   WALK_MODEL = ';'
   DRIVE_MODEL = ' '
   KR_MODEL = ';'
   TABIN = 'MI.1.7'
  ELSEIF (ACCESS = 4)
   ACCESS_MODE = 'KR'
   EGRESS_MODE = 'WK'
   WALK_MODEL = ';'
   DRIVE_MODEL = ';'
   KR_MODEL = ' '
   TABIN = 'MI.1.4'
  ELSEIF (ACCESS = 5)
   ACCESS_MODE = 'WK'
   EGRESS_MODE = 'KR'
   WALK_MODEL = ';'
   DRIVE_MODEL = ';'
   KR_MODEL = ' '
   TABIN = 'MI.1.1'
  ENDIF


;---------------------------------------------------------------------------
; Assign All Bus Transit Trips
;---------------------------------------------------------------------------

RUN PGM = PUBLIC TRANSPORT
FILEI NETI       = "%SCEN_DIRECTORY%\outputs\trn_net\%_ITER_%_@TIME_PERIOD@_@ACCESS_MODE@_AB_@EGRESS_MODE@.NET"
FILEI MATI[1]    =  @MATIN@

FILEI ROUTEI     = "%SCEN_DIRECTORY%\outputs\trn_net\%_ITER_%_@TIME_PERIOD@_@ACCESS_MODE@_AB_@EGRESS_MODE@.RTE"
FILEI FAREMATI[1] = %SCEN_DIRECTORY%\outputs\trn_net\Metrorail_Fare.mat
FILEI FAREMATI[2] = %SCEN_DIRECTORY%\outputs\trn_net\VRE_Fare.mat
FILEI FAREMATI[3] = %SCEN_DIRECTORY%\outputs\trn_net\MARC_Fare.mat
FILEO REPORTO    = "%SCEN_DIRECTORY%\outputs\trn_assign\%_ITER_%_@TIME_PERIOD@_@ACCESS_MODE@_AB_@EGRESS_MODE@_ASGN.PRN"
FILEO LINKO      = "%SCEN_DIRECTORY%\outputs\trn_assign\%_ITER_%_@TIME_PERIOD@_@ACCESS_MODE@_AB_@EGRESS_MODE@_LINKVOL.DBF", ONOFFS=Y
FILEO STOP2STOPO = "%SCEN_DIRECTORY%\outputs\trn_assign\%_ITER_%_@TIME_PERIOD@_@ACCESS_MODE@_AB_@EGRESS_MODE@_S2Svol.dbf", ACCUMULATE = ADJACENTBYMODE,
                      NODES= 1-70000, MODES = 3  , LIST=N

FILEI FAREI = @SCEN_DIRECTORY@\inputs\trn\FARE_@TIME_PERIOD@.DAT

PARAMETERS EFARE=T,TRIPSIJ[1] = @TABIN@

REPORT LINES=T SKIP0=T

ZONEMSG=50

ENDRUN


ENDLOOP ;---- ACCESS ----
ENDLOOP ;---- PERIOD ----
