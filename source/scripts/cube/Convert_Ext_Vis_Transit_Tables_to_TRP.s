; Convert_Ext_Vis_Transit_Tables_to_TRP.s
; Nov 2021  
; Needs to be run when new OMX format external transit or visitor trip
; tables are available
; Gen3 Model expects TRP format skims in inputs\trn\External_Visitor_Transit
;---------------------------------------------------------------

;*** Copy fixed External TRANSIT OMX matrices to TRP format

CONVERTMAT FROM="inputs\trn\External_Visitor_Transit\AM_External.omx" TO="inputs\trn\External_Visitor_Transit\AM_External.TRP" FORMAT=TPP COMPRESSION=0
CONVERTMAT FROM="inputs\trn\External_Visitor_Transit\MD_External.omx" TO="inputs\trn\External_Visitor_Transit\MD_External.TRP" FORMAT=TPP COMPRESSION=0
CONVERTMAT FROM="inputs\trn\External_Visitor_Transit\PM_External.omx" TO="inputs\trn\External_Visitor_Transit\PM_External.TRP" FORMAT=TPP COMPRESSION=0
CONVERTMAT FROM="inputs\trn\External_Visitor_Transit\NT_External.omx" TO="inputs\trn\External_Visitor_Transit\NT_External.TRP" FORMAT=TPP COMPRESSION=0


;*** Copy fixed Visitor TRANSIT OMX matrices to TRP format

CONVERTMAT FROM="inputs\trn\External_Visitor_Transit\AM_Visitor.omx" TO="inputs\trn\External_Visitor_Transit\AM_Visitor.TRP" FORMAT=TPP COMPRESSION=0
CONVERTMAT FROM="inputs\trn\External_Visitor_Transit\MD_Visitor.omx" TO="inputs\trn\External_Visitor_Transit\MD_Visitor.TRP" FORMAT=TPP COMPRESSION=0
CONVERTMAT FROM="inputs\trn\External_Visitor_Transit\PM_Visitor.omx" TO="inputs\trn\External_Visitor_Transit\PM_Visitor.TRP" FORMAT=TPP COMPRESSION=0
CONVERTMAT FROM="inputs\trn\External_Visitor_Transit\NT_Visitor.omx" TO="inputs\trn\External_Visitor_Transit\NT_Visitor.TRP" FORMAT=TPP COMPRESSION=0
