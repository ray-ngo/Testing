:: Create output folder and its structure

if not exist "outputs" (
   mkdir outputs
   mkdir outputs\activitysim
   mkdir outputs\auxiliary
   mkdir outputs\hwy_assign
   mkdir outputs\hwy_net
   mkdir outputs\landuse
   mkdir outputs\reports
   mkdir outputs\skims
   mkdir outputs\trn_assign
   mkdir outputs\trn_net
   mkdir outputs\activitysim\cache
   mkdir outputs\activitysim\log
   mkdir outputs\activitysim\trace
   mkdir outputs\skims\OMX_Skims
   mkdir outputs\visualizer
)
IF NOT EXIST "outputs\reports" mkdir outputs\reports
