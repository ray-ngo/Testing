*del voya*.prn
;
;=====================================================================================================
;  IXXI_TripGeneration.s                                                                             =
;  This process prepares auto passenger IX and XI trip productions                                   =
;=====================================================================================================

ZONESIZE       =  3722                       ;  No. of TAZs
LastIZn        =  3675                       ;  Last Internal TAZ no.
FirstExZn = 3676

Skim_Inp = 'outputs\skims\%_prev_%_MD_sov.skm'
Acc_Out = 'outputs\auxiliary\ixxi_access.dbf'
ExtPA_Inp = 'inputs\auxiliary\Ext_PsAs.dbf'
HBWIX_decay = -0.08 
HBNWIX_decay = -0.08

HBWXI_decay = -0.08
HBNWXI_decay = -0.08

NHBXI_decay = -0.08
NHBIX_decay = -0.08


ZData_Inp = 'inputs\landuse\land_use.csv'
IXXIP_Out = 'outputs\auxiliary\ixxi_prod.dbf'

ADRAM  = 'outputs\auxiliary\%_iter_%_am_adr.mat'
ADRMD  = 'outputs\auxiliary\%_iter_%_md_adr.mat'
ADRPM  = 'outputs\auxiliary\%_iter_%_pm_adr.mat'
ADRNT  = 'outputs\auxiliary\%_iter_%_nt_adr.mat'

TODFtrs = '..\support\todixxi_2018HTS.dbf'

; TOD ARRAY parameters
Pur = 5  ;  1/HBW,   2/HBS,    3/HBO, 4/NHW, 5/NHO
Mod = 4  ;  1/Adr,   2/DrAlone 3/CarPoolPsn  4/Transit
Dir = 2  ;  1/H>NH,  2/NH>H
Per = 4  ;  1/AM,    2/MD,     3/PM,  4/NT

COEF_HBWIX_HH = 0.0539
COEF_HBWIX_ACC = 0.0136
COEF_HBWXI_RETEMP = 0.1175
COEF_HBWXI_NRETEMP = 0.0132
COEF_HBWXI_ACC = 0 ;0.014

COEF_HBNWIX_HH = 0.0487
COEF_HBNWIX_ACC = 0.0083
COEF_HBNWXI_RETEMP = 0.0765
COEF_HBNWXI_NRETEMP = 0.0027
COEF_HBNWXI_ACC = 0 ;0.012

COEF_NHBIX_RETEMP = 0.0765
COEF_NHBIX_NRETEMP = 0
COEF_NHBIX_HH = 0.0171
COEF_NHBIX_ACC = 0 ; 0.0099

COEF_NHBXI_RETEMP = 0.0538
COEF_NHBXI_NRETEMP = 0.0066
COEF_NHBXI_HH = 0.0045
COEF_NHBXI_ACC = 0 ;0.0085

DCUtils = 'outputs\auxiliary\ixxidcutils.mat'

C_COST_HBWIX = -0.0011 
C_TIME_HBWIX = -0.0840

C_COST_HBWXI = -0.00005 
C_TIME_HBWXI = -0.0010

C_COST_NHBXI = -0.00005
C_TIME_NHBXI = -0.0010

C_COST_HBNWIX = 0.0011 
C_TIME_HBNWIX = -0.0510

C_COST_HBNWXI = -0.00006 
C_TIME_HBNWXI = -0.0010

C_COST_NHBIX = -0.0023 
C_TIME_NHBIX = -0.0274

AOC=19.26 ;cents per mile

IXXI_Trips = 'outputs\auxiliary\autopaxixxi.trp'

;#TODO: These can probably be removed after calibration (maybe)
sp_file = 'outputs\auxiliary\sp.dbf'
tlf_compare_file = 'outputs\auxiliary\ixxi_tlf.dbf'
obs_tlf_file = 'outputs\auxiliary\observedtlf.dbf'

; Compute decay
RUN PGM=MATRIX
FILEI MATI[1] = @Skim_Inp@
FILEI ZDATI[1] = @ExtPA_Inp@
FILEO RECO[1] = @Acc_Out@ FIELDS = TAZ, HBWIXA, HBNWIXA, NHBIXA, HBWXIA, HBNWXIA, NHBXIA

MW[1] = MI.1.DIST10 / 10.0

hbwix = 0
hbnwix = 0

hbwxi = 0
hbnwxi = 0

IF(I <= @LastIZn@)
	JLOOP INCLUDE=@FirstExZn@-@ZONESIZE@
		IF(MW[1] > 0) 
			hbwix = hbwix + exp(@HBWIX_decay@ * MW[1]) * ZI.1.HBW_IX[J]
			hbnwix = hbnwix + exp(@HBNWIX_decay@ * MW[1]) * (ZI.1.HBS_IX[J] + ZI.1.HBO_IX[J])
			nhbix = nhbix + exp(@NHBIX_decay@ * MW[1]) * (ZI.1.NHB_IX[J])
			
			hbwxi = hbwxi + exp(@HBWXI_decay@ * MW[1]) * ZI.1.HBW_XI[J]
			hbnwxi = hbnwxi + exp(@HBNWXI_decay@ * MW[1]) * (ZI.1.HBS_XI[J] + ZI.1.HBO_XI[J])
			nhbxi = nhbxi + exp(@NHBXI_decay@ * MW[1]) * (ZI.1.NHB_XI[j])
		ENDIF
	ENDJLOOP
ENDIF

RO.TAZ = I
RO.HBWIXA = hbwix
RO.HBNWIXA = hbnwix
RO.NHBIXA = nhbix

RO.HBWXIA = hbwxi
RO.HBNWXIA = hbnwxi
RO.NHBXIA = nhbxi
WRITE RECO = 1

ENDRUN

; Compute Gen, balance to counts
RUN PGM=TRIPGEN
FILEI ZDATI[1] = @ZData_Inp@, Z = #1, HH = #2, HHPOP = #3, GQPOP = #4, TOTPOP = #5, TOTEMP = #6, INDEMP = #7, RETEMP = #8, OFFEMP = #9, 
  OTHEMP = #10, JURCODE = #11, LANDAREA = #12, TAZXCRD = #13, TAZYCRD = #14, K_8 = #15, G9_12 = #16,
  COLLEGE = #17, Park_Acres = #18, GC_Acres = #19, PRKCST = #20, OPRKCST = #21, TERMINAL = #22, AREATYPE = #23
FILEI ZDATI[2] = @Acc_Out@
FILEI ZDATI[3] = @ExtPA_Inp@
FILEO PAO[1] = @IXXIP_Out@ LIST = Z, P[1], A[1], P[2], A[2], P[3], A[3], P[4], A[4], P[5], A[5], P[6], A[6], 
	DBF = T, NAMES = TAZ, HBW_IXP, HBW_IXA, HBNW_IXP, HBNW_IXA, NHB_IXP, NHB_IXA, HBW_XIP, HBW_XIA, HBNW_XIP, HBNW_XIA, NHB_XIP, NHB_XIA

PAR ZONES = @ZONESIZE@

PROCESS PHASE = ILOOP
	IF(I <= @LastIZn@)
		; IX - HBW, HBNW, NHB
		P[1] = @COEF_HBWIX_HH@ * ZI.1.HH + @COEF_HBWIX_ACC@ * ZI.2.HBWIXA 
		A[1] = 0
		P[2] = @COEF_HBNWIX_HH@ * ZI.1.HH + @COEF_HBNWIX_ACC@ * ZI.2.HBNWIXA
		A[2] = 0
		P[3] = @COEF_NHBIX_HH@ * ZI.1.HH + @COEF_NHBIX_RETEMP@ * ZI.1.RETEMP + @COEF_NHBIX_NRETEMP@ * (ZI.1.INDEMP + ZI.1.OFFEMP + ZI.1.OTHEMP) + @COEF_NHBIX_ACC@ * ZI.2.NHBIXA
		A[3] = 0
		; XI - HBW, HBNW, NHB
		P[4] = 0
		A[4] = @COEF_HBWXI_RETEMP@ * ZI.1.RETEMP + @COEF_HBWXI_NRETEMP@ * (ZI.1.INDEMP + ZI.1.OFFEMP + ZI.1.OTHEMP) + @COEF_HBWXI_ACC@ * ZI.2.HBWXIA
		P[5] = 0
		A[5] = @COEF_HBNWXI_RETEMP@ * ZI.1.RETEMP + @COEF_HBNWXI_NRETEMP@ * (ZI.1.INDEMP + ZI.1.OFFEMP + ZI.1.OTHEMP) + @COEF_HBNWXI_ACC@ * ZI.2.HBNWXIA
		P[6] = 0
		A[6] = @COEF_NHBXI_HH@ * ZI.1.HH + @COEF_NHBXI_RETEMP@ * ZI.1.RETEMP + @COEF_NHBXI_NRETEMP@ * (ZI.1.INDEMP + ZI.1.OFFEMP + ZI.1.OTHEMP) + @COEF_NHBXI_ACC@ * ZI.2.NHBXIA
	ELSE
		; IX - HBW, HBNW, NHB
		P[1] = 0
		A[1] = ZI.3.HBW_IX
		P[2] = 0
		A[2] = (ZI.3.HBS_IX + ZI.3.HBO_IX)
		P[3] = 0	
		A[3] = ZI.3.NHB_IX
		; XI - HBW, HBNW, NHB
		P[4] = ZI.3.HBW_XI
		A[4] = 0
		P[5] = (ZI.3.HBS_XI + ZI.3.HBO_XI)
		A[5] = 0
		P[6] = ZI.3.NHB_XI
		A[6] = 0
	ENDIF
ENDPHASE

PHASE = ADJUST
	BALANCE P2A=1,2,3 A2P=4,5,6
ENDPHASE

ENDRUN

; Destination Choice Utilities
RUN PGM=MATRIX
FILEI MATI[1] = @Skim_Inp@
FILEI ZDATI[1] = @ZData_Inp@, Z = #1, HH = #2, HHPOP = #3, GQPOP = #4, TOTPOP = #5, TOTEMP = #6, INDEMP = #7, RETEMP = #8, OFFEMP = #9, 
  OTHEMP = #10, JURCODE = #11, LANDAREA = #12, TAZXCRD = #13, TAZYCRD = #14, K_8 = #15, G9_12 = #16,
  COLLEGE = #17, Park_Acres = #18, GC_Acres = #19, PRKCST = #20, OPRKCST = #21, TERMINAL = #22, AREATYPE = #23
FILEO MATO[1] = @DCUtils@ MO=101-106 NAME=U_HBWIX, U_HBNWIX, U_NHBIX, U_HBWXI, U_HBNWXI, U_NHBXI

MW[1] = MI.1.DIST10 / 10.0
MW[2] = MI.1.TIME
MW[3] = MI.1.TOLL

IF(I > @LastIZn@)
	JLOOP INCLUDE=1-@LastIZn@
		IF(MW[1] > 1)
			MW[101] = @C_COST_HBWIX@ * (@AOC@ * MW[1] + MW[3])  + @C_TIME_HBWIX@ * MW[2]
			MW[102] = @C_COST_HBNWIX@ * (@AOC@ * MW[1] + MW[3]) + @C_TIME_HBNWIX@ * MW[2]
			MW[103] = @C_COST_NHBIX@ *(@AOC@ * MW[1] + MW[3]) + @C_TIME_NHBIX@ *  MW[2]
			MW[104] = @C_COST_HBWXI@ * (@AOC@ * MW[1] + MW[3])  + @C_TIME_HBWXI@ * MW[2]
			MW[105] = @C_COST_HBNWXI@ * (@AOC@ * MW[1] + MW[3]) + @C_TIME_HBNWXI@ * MW[2]
			MW[106] = @C_COST_NHBXI@ *(@AOC@ * MW[1] + MW[3]) + @C_TIME_NHBXI@ *  MW[2]
		ELSE
			MW[101] = -999
			MW[102] = -999
			MW[103] = -999
			MW[104] = -999
			MW[105] = -999
			MW[106] = -999
		ENDIF
	ENDJLOOP
ENDIF

ENDRUN

; Destination Choice 
RUN PGM=MATRIX
FILEI MATI[1] = @DCUtils@
FILEI DBI[1] = @IXXIP_Out@
FILEO MATO[1] = @IXXI_Trips@ MO=101-106 NAME=HBWIX, HBNWIX, NHBIX, HBWXI, HBNWXI, NHBXI

MW[1] = -1 * MI.1.U_HBWIX
MW[2] = -1 * MI.1.U_HBNWIX
MW[3] = -1 * MI.1.U_NHBIX
;MW[4] = -1 * MI.1.U_HBWXI
;MW[5] = -1 * MI.1.U_HBNWXI
;MW[6] = -1 * MI.1.U_NHBXI

MW[4] = MW[1] ;-1 * MI.1.U_HBWIX.T
MW[5] = MW[2] ;-1 * MI.1.U_HBNWIX.T
MW[6] = MW[3] ;-1 * MI.1.U_NHBIX.T

x1 = DBIReadRecord(1, I)

HBW_IX = DI.1.HBW_IXA 
HBNW_IX = DI.1.HBNW_IXA
NHB_IX = DI.1.NHB_IXA
HBW_XIP_PT = DI.1.HBW_XIP
HBNW_XIP_PT = DI.1.HBNW_XIP
NHB_XIP_PT = DI.1.NHB_XIP

XCHOICE,
    ALTERNATIVES = 101,
    DEMAND = HBW_IX,
    DESTSPLIT = TOTAL 1.0, EXCLUDE = @FirstExZn@-@ZONESIZE@,
    ODEMANDMW = 101,
    STARTMW = 300,
    UTILITIESMW = 1 
	
XCHOICE,
    ALTERNATIVES = 102,
    DEMAND = HBNW_IX,
    DESTSPLIT = TOTAL 1.0, EXCLUDE = @FirstExZn@-@ZONESIZE@,
    ODEMANDMW = 102,
    STARTMW = 300,
    UTILITIESMW = 2 

XCHOICE,
    ALTERNATIVES = 103,
    DEMAND = NHB_IX,
    DESTSPLIT = TOTAL 1.0, EXCLUDE = @FirstExZn@-@ZONESIZE@, 
    ODEMANDMW = 103,
    STARTMW = 300,
    UTILITIESMW = 3 

XCHOICE,
    ALTERNATIVES = 104,
    DEMAND = HBW_XIP_PT,
    DESTSPLIT = TOTAL 1.0, EXCLUDE = @FirstExZn@-@ZONESIZE@,
    ODEMANDMW = 104,
    STARTMW = 300,
    UTILITIESMW = 4 
	
XCHOICE,
    ALTERNATIVES = 105,
    DEMAND = HBNW_XIP_PT,
    DESTSPLIT = TOTAL 1.0, EXCLUDE = @FirstExZn@-@ZONESIZE@,
    ODEMANDMW = 105,
    STARTMW = 300,
    UTILITIESMW = 5 
	
XCHOICE,
    ALTERNATIVES = 106,
    DEMAND = NHB_XIP_PT,
    DESTSPLIT = TOTAL 1.0, EXCLUDE = @FirstExZn@-@ZONESIZE@, 
    ODEMANDMW = 106,
    STARTMW = 300,
    UTILITIESMW = 6 

ENDRUN

;#NOTE: @IXXI_Trips@ IX trips need to be transposed before use!
; Split to TOD

RUN PGM=MATRIX
FILEI DBI[1]  = @TODFtrs@
FILEI MATI[1] = @IXXI_Trips@ 
FILEO MATO[1] = @ADRAM@ MO=14,114,214, NAME = AM_ADRs_1, AM_ADRs_2, AM_ADRs_3, DEC=3*3
FILEO MATO[2] = @ADRMD@ MO=24,124,224, NAME = MD_ADRs_1, MD_ADRs_2, MD_ADRs_3, DEC=3*3
FILEO MATO[3] = @ADRPM@ MO=34,134,234, NAME = PM_ADRs_1, PM_ADRs_2, PM_ADRs_3, DEC=3*3
FILEO MATO[4] = @ADRNT@ MO=44,144,244, NAME = NT_ADRs_1, NT_ADRs_2, NT_ADRs_3, DEC=3*3

; Mode choices - simple factors based on 2018 HTS
; These are basically percent of weighted trips to convert to mode. The next script
; (Prepare_Trip_Tables_for_Assignment.s) expects auto drivers, so the output of this
; is auto drivers by mode

ARRAY XI_Mode_Factors = 3
ARRAY IX_Mode_Factors = 3

XI_Mode_Factors[1] = 0.623
XI_Mode_Factors[2] = 0.215
XI_Mode_Factors[3] = 0.162

IX_Mode_Factors[1] = 0.682
IX_Mode_Factors[2] = 0.202
IX_Mode_Factors[3] = 0.115

MW[1] = MI.1.HBWIX.T
MW[2] = MI.1.HBWXI
MW[3] = MI.1.HBNWIX.T
MW[4] = MI.1.HBNWXI
MW[5] = MI.1.NHBIX.T
MW[6] = MI.1.NHBXI

MW[10] = 0

Array TODFtrs  =@Pur@,@Mod@,@Dir@,@Per@
;==============================================================================================
;==============================================================================================
; Read in Time of Day factor file and populate TOD factor array
LOOP K = 1,dbi.1.NUMRECORDS       ;;PURP    MODE    DIR     AM      MD      PM      OP

     x = DBIReadRecord(1,k)
           count       = dbi.1.recno
           TODFtrs[di.1.Purp][di.1.Mode][di.1.DIR][1] = di.1.AM
           TODFtrs[di.1.Purp][di.1.Mode][di.1.DIR][2] = di.1.MD
           TODFtrs[di.1.Purp][di.1.Mode][di.1.DIR][3] = di.1.PM
           TODFtrs[di.1.Purp][di.1.Mode][di.1.DIR][4] = di.1.OP
ENDLOOP

; AM Peak DA
MW[11] = MW[1] * (TODFtrs[1][2][1][1]/100.00) * IX_Mode_Factors[1] + MW[2] * (TODFtrs[1][2][2][1]/100.00) * XI_Mode_Factors[1]   ;   HBW / DA 
MW[12] = MW[3] * (TODFtrs[3][2][1][1]/100.00) * IX_Mode_Factors[1] + MW[4] * (TODFtrs[3][2][2][1]/100.00) * XI_Mode_Factors[1]   ;   HBO / DA 
MW[13] = MW[5] * (TODFtrs[5][2][1][1]/100.00) * IX_Mode_Factors[1] + MW[6] * (TODFtrs[5][2][2][1]/100.00) * XI_Mode_Factors[1]   ;   NHO / DA 
MW[14] = MW[11] + MW[12] + MW[13]

; AM Peak SR2
MW[111] = MW[1] * (TODFtrs[1][2][1][1]/100.00) * IX_Mode_Factors[2] + MW[2] * (TODFtrs[1][2][2][1]/100.00) * XI_Mode_Factors[2]  ;   HBW / SR2 
MW[112] = MW[3] * (TODFtrs[3][2][1][1]/100.00) * IX_Mode_Factors[2] + MW[4] * (TODFtrs[3][2][2][1]/100.00) * XI_Mode_Factors[2]  ;   HBO / SR2 
MW[113] = MW[5] * (TODFtrs[5][2][1][1]/100.00) * IX_Mode_Factors[2] + MW[6] * (TODFtrs[5][2][2][1]/100.00) * XI_Mode_Factors[2]  ;   NHO / SR2 
MW[114] = MW[111] + MW[112] + MW[113]

; AM Peak SR3
MW[211] = MW[1] * (TODFtrs[1][2][1][1]/100.00) * IX_Mode_Factors[3] + MW[2] * (TODFtrs[1][2][2][1]/100.00) * XI_Mode_Factors[3]  ;   HBW / SR3 
MW[212] = MW[3] * (TODFtrs[3][2][1][1]/100.00) * IX_Mode_Factors[3] + MW[4] * (TODFtrs[3][2][2][1]/100.00) * XI_Mode_Factors[3]  ;   HBO / SR3 
MW[213] = MW[5] * (TODFtrs[5][2][1][1]/100.00) * IX_Mode_Factors[3] + MW[6] * (TODFtrs[5][2][2][1]/100.00) * XI_Mode_Factors[3]  ;   NHO / SR3 
MW[214] = MW[211] + MW[212] + MW[213]

; MD DA
MW[21] = MW[1] * (TODFtrs[1][2][1][2]/100.00) * IX_Mode_Factors[1] + MW[2] * (TODFtrs[1][2][2][2]/100.00) * XI_Mode_Factors[1]   ;   HBW / DA 
MW[22] = MW[3] * (TODFtrs[3][2][1][2]/100.00) * IX_Mode_Factors[1] + MW[4] * (TODFtrs[3][2][2][2]/100.00) * XI_Mode_Factors[1]   ;   HBO / DA 
MW[23] = MW[5] * (TODFtrs[5][2][1][2]/100.00) * IX_Mode_Factors[1] + MW[6] * (TODFtrs[5][2][2][2]/100.00) * XI_Mode_Factors[1]   ;   NHO / DA 
MW[24] = MW[21] + MW[22] + MW[23]

; MD SR2
MW[121] = MW[1] * (TODFtrs[1][2][1][2]/100.00) * IX_Mode_Factors[2] + MW[2] * (TODFtrs[1][2][2][2]/100.00) * XI_Mode_Factors[2]  ;   HBW / SR2 
MW[122] = MW[3] * (TODFtrs[3][2][1][2]/100.00) * IX_Mode_Factors[2] + MW[4] * (TODFtrs[3][2][2][2]/100.00) * XI_Mode_Factors[2]  ;   HBO / SR2 
MW[123] = MW[5] * (TODFtrs[5][2][1][2]/100.00) * IX_Mode_Factors[2] + MW[6] * (TODFtrs[5][2][2][2]/100.00) * XI_Mode_Factors[2]  ;   NHO / SR2 
MW[124] = MW[121] + MW[122] + MW[123]

; MD SR3
MW[221] = MW[1] * (TODFtrs[1][2][1][2]/100.00) * IX_Mode_Factors[3] + MW[2] * (TODFtrs[1][2][2][2]/100.00) * XI_Mode_Factors[3]  ;   HBW / SR3 
MW[222] = MW[3] * (TODFtrs[3][2][1][2]/100.00) * IX_Mode_Factors[3] + MW[4] * (TODFtrs[3][2][2][2]/100.00) * XI_Mode_Factors[3]  ;   HBO / SR3 
MW[223] = MW[5] * (TODFtrs[5][2][1][2]/100.00) * IX_Mode_Factors[3] + MW[6] * (TODFtrs[5][2][2][2]/100.00) * XI_Mode_Factors[3]  ;   NHO / SR3 
MW[224] = MW[221] + MW[222] + MW[223]

; PM Peak DA
MW[31] = MW[1] * (TODFtrs[1][2][1][3]/100.00) * IX_Mode_Factors[1] + MW[2] * (TODFtrs[1][2][2][3]/100.00) * XI_Mode_Factors[1]   ;   HBW / DA 
MW[32] = MW[3] * (TODFtrs[3][2][1][3]/100.00) * IX_Mode_Factors[1] + MW[4] * (TODFtrs[3][2][2][3]/100.00) * XI_Mode_Factors[1]   ;   HBO / DA 
MW[33] = MW[5] * (TODFtrs[5][2][1][3]/100.00) * IX_Mode_Factors[1] + MW[6] * (TODFtrs[5][2][2][3]/100.00) * XI_Mode_Factors[1]   ;   NHO / DA 
MW[34] = MW[31] + MW[32] + MW[33]

; PM Peak SR2
MW[131] = MW[1] * (TODFtrs[1][2][1][3]/100.00) * IX_Mode_Factors[2] + MW[2] * (TODFtrs[1][2][2][3]/100.00) * XI_Mode_Factors[2]  ;   HBW / SR2 
MW[132] = MW[3] * (TODFtrs[3][2][1][3]/100.00) * IX_Mode_Factors[2] + MW[4] * (TODFtrs[3][2][2][3]/100.00) * XI_Mode_Factors[2]  ;   HBO / SR2 
MW[133] = MW[5] * (TODFtrs[5][2][1][3]/100.00) * IX_Mode_Factors[2] + MW[6] * (TODFtrs[5][2][2][3]/100.00) * XI_Mode_Factors[2]  ;   NHO / SR2 
MW[134] = MW[131] + MW[132] + MW[133]

; PM Peak SR3
MW[231] = MW[1] * (TODFtrs[1][2][1][3]/100.00) * IX_Mode_Factors[3] + MW[2] * (TODFtrs[1][2][2][3]/100.00) * XI_Mode_Factors[3]  ;   HBW / SR3 
MW[232] = MW[3] * (TODFtrs[3][2][1][3]/100.00) * IX_Mode_Factors[3] + MW[4] * (TODFtrs[3][2][2][3]/100.00) * XI_Mode_Factors[3]  ;   HBO / SR3 
MW[233] = MW[5] * (TODFtrs[5][2][1][3]/100.00) * IX_Mode_Factors[3] + MW[6] * (TODFtrs[5][2][2][3]/100.00) * XI_Mode_Factors[3]  ;   NHO / SR3 
MW[234] = MW[231] + MW[232] + MW[233]

; NT DA
MW[41] = MW[1] * (TODFtrs[1][2][1][4]/100.00) * IX_Mode_Factors[1] + MW[2] * (TODFtrs[1][2][2][4]/100.00) * XI_Mode_Factors[1]   ;   HBW / DA 
MW[42] = MW[3] * (TODFtrs[3][2][1][4]/100.00) * IX_Mode_Factors[1] + MW[4] * (TODFtrs[3][2][2][4]/100.00) * XI_Mode_Factors[1]   ;   HBO / DA 
MW[43] = MW[5] * (TODFtrs[5][2][1][4]/100.00) * IX_Mode_Factors[1] + MW[6] * (TODFtrs[5][2][2][4]/100.00) * XI_Mode_Factors[1]   ;   NHO / DA 
MW[44] = MW[41] + MW[42] + MW[43]

; NT SR2
MW[141] = MW[1] * (TODFtrs[1][2][1][4]/100.00) * IX_Mode_Factors[2] + MW[2] * (TODFtrs[1][2][2][4]/100.00) * XI_Mode_Factors[2]  ;   HBW / SR2 
MW[142] = MW[3] * (TODFtrs[3][2][1][4]/100.00) * IX_Mode_Factors[2] + MW[4] * (TODFtrs[3][2][2][4]/100.00) * XI_Mode_Factors[2]  ;   HBO / SR2 
MW[143] = MW[5] * (TODFtrs[5][2][1][4]/100.00) * IX_Mode_Factors[2] + MW[6] * (TODFtrs[5][2][2][4]/100.00) * XI_Mode_Factors[2]  ;   NHO / SR2 
MW[144] = MW[141] + MW[142] + MW[143]

; NT SR3
MW[241] = MW[1] * (TODFtrs[1][2][1][4]/100.00) * IX_Mode_Factors[3] + MW[2] * (TODFtrs[1][2][2][4]/100.00) * XI_Mode_Factors[3]  ;   HBW / SR3 
MW[242] = MW[3] * (TODFtrs[3][2][1][4]/100.00) * IX_Mode_Factors[3] + MW[4] * (TODFtrs[3][2][2][4]/100.00) * XI_Mode_Factors[3]  ;   HBO / SR3 
MW[243] = MW[5] * (TODFtrs[5][2][1][4]/100.00) * IX_Mode_Factors[3] + MW[6] * (TODFtrs[5][2][2][4]/100.00) * XI_Mode_Factors[3]  ;   NHO / SR3 
MW[244] = MW[241] + MW[242] + MW[243]

ENDRUN

CONVERTMAT FROM='outputs\auxiliary\%_iter_%_am_adr.mat' TO='outputs\auxiliary\%_iter_%_am_adr.omx' COMPRESSION=4
CONVERTMAT FROM='outputs\auxiliary\%_iter_%_md_adr.mat' TO='outputs\auxiliary\%_iter_%_md_adr.omx' COMPRESSION=4
CONVERTMAT FROM='outputs\auxiliary\%_iter_%_pm_adr.mat' TO='outputs\auxiliary\%_iter_%_pm_adr.omx' COMPRESSION=4
CONVERTMAT FROM='outputs\auxiliary\%_iter_%_nt_adr.mat' TO='outputs\auxiliary\%_iter_%_nt_adr.omx' COMPRESSION=4