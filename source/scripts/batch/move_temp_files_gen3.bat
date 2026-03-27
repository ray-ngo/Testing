@echo off

:: move_temp_files_gen3.bat utilizing PS

echo(
echo Create the subfolder to hold the temp files
if not exist temp_files (mkdir temp_files)

echo(
echo Change working folder to the output folder
cd outputs

:: Calculate stats BEFORE move
powershell -noprofile -Command "Get-ChildItem -Recurse | Measure-Object -property Length -Sum| select-object @{n='Total size of outputs files before moving temp files (MB)';e={ '{0:N2}' -f ($_.Sum / 1MB)}}, @{n='Files Count';e={$_.Count}}| Out-File tot_output_files_before_move2temp.txt"

echo(
echo Move pipeline folders to temp_files
if not exist "..\temp_files\activitysim" mkdir "..\temp_files\activitysim"
for /D %%H in (activitysim\*pipeline*) do (
    move "%%H" "..\temp_files\activitysim\" >NUL 2>&1
)

echo(
echo Move all matching files to temp_files using PowerShell
echo (This automatically preserves the directory structure)

powershell -noprofile -Command "$sourceRoot=Get-Location;Get-ChildItem -Recurse -Include *.omx,*.RTE,*.tem?,temp.*,temp*.net,transit.temp.*,*.skf,*.def,*.lkloop,pp*,i1*,i2*,i3*,breadcrumbs.yaml,cdap_spec_*.csv,Link_TAZ_Check.txt,Default.VPR,zonehwy.TEM,Convert_trip_tables_omx_to_trp.RPT,debug*.TXT,i4_omx_trip_tables_from_ActivitySim_*.RPT|ForEach-Object{$relativePath=$_.FullName.Substring($sourceRoot.Path.Length+1);$destPath=Join-Path '..\temp_files' $relativePath;$destDir=Split-Path $destPath -Parent;if(!(Test-Path $destDir)){New-Item -ItemType Directory -Path $destDir -Force|Out-Null};Move-Item $_.FullName $destPath -Force}"

if errorlevel 1 goto error

:: Delete outputs/visualizer/runtime and outputs/skims/OMX_Skims folders
powershell -noprofile -Command "rm .\visualizer\runtime,.\skims\OMX_Skims -Force -r"

goto end

:error
echo Processing Error....
PAUSE

:end
:: Calculate stats AFTER move
powershell -noprofile -Command "Get-ChildItem -Recurse | Measure-Object -property Length -Sum| select-object @{n='Total size of outputs files after moving temp files (MB)';e={ '{0:N2}' -f ($_.Sum / 1MB)}}, @{n='Files Count';e={$_.Count}}| Out-File tot_output_files_after_move2temp.txt"

echo(
echo ***** Number of and size of output files BEFORE moving temp files
type tot_output_files_before_move2temp.txt

echo(
echo ***** Number of and size of output files AFTER moving temp files
type tot_output_files_after_move2temp.txt

CD..
del DJ*.* TPPL*.* *.VAR TPMAIN_*.* *script.cmdstart.* *script.command.* /q /f
