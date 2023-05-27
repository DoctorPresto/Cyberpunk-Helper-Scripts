@echo off
setlocal enabledelayedexpansion

echo Establishing connection.....

:: Check if we are in the cyberpunk directory or if the cyberpunk directory was dragged onto the script. Mostly stolen from Mana
if "%~1" == "" (
  pushd %~dp0
  set "CYBERPUNKDIR=!CD!"
  popd
) else (
  set "CYBERPUNKDIR=%~1"
)

::if not, deploy R.A.B.I.D.S and shut down
if not exist "%CYBERPUNKDIR%\bin\x64\Cyberpunk2077.exe" (
  echo.
  echo Wake the f*ck up Samurai! This isn't your Cyberpunk install directory
  echo Either place me in your Cyberpunk 2077 folder and try again
  echo or drag and drop it onto me from Windows Explorer
  echo.
  echo Deploying Roving Autonomous Bartmoss Interface Drones....
  FOR /L %%S IN (10, -1, 1) DO (
    set /p =%%S ...!carret!<nul
    ping -n 2 127.0.0.1 > nul 2>&1
  )
  goto :eof
)
echo Deploying Datamine
:: Check if the LOGS folder already exists in the install directory, if not, create it
if not exist "%CYBERPUNKDIR%\_LOGS" mkdir "%CYBERPUNKDIR%\_LOGS"

:: Set the output file path for the FilteredLogs file
set "output_file=%CYBERPUNKDIR%\_LOGS\FilteredLogs.txt"

:: if there's already a FilteredLogs.txt file, clear the content so that all of the errors listed were recorded on this run this run
break > "%output_file%"

:: Set the path to the cyberpunk exe 
set "exe_path=%CYBERPUNKDIR%\bin\x64\Cyberpunk2077.exe"
:: Get exe version using wmic datafile command because it works
for /f "tokens=2 delims==" %%a in ('wmic datafile where name^="!exe_path:\=\\!" get version /value') do (
    for /f "delims=" %%b in ("%%a") do set "version=%%b"
)      

:: if not the current game version, yell at the user and deploy R.A.B.I.D.S.
if not "!version!"=="3.0.71.13361" (
  echo Please update the game before proceeding
  echo Deploying Roving Autonomous Bartmoss Interface Drones....
  FOR /L %%S IN (10, -1, 1) DO (
    set /p =%%S ...!carret!<nul
    ping -n 2 127.0.0.1 > nul 2>&1
  )
  goto :eof
)

:: Append version info to the output file
echo Version: !version! > "%output_file%"

:: get CET Version using wmic because nothing else wanted to work 
set "version_dll_path=%CYBERPUNKDIR%\bin\x64\version.dll"
for /f "tokens=2 delims==" %%c in ('wmic datafile where name^="!version_dll_path:\=\\!" get version /value') do (
    for /f "delims=" %%d in ("%%c") do set "version_dll=%%d"
)
:: Append CET Version info to the output file
echo Version: !version!  CET Version: !version_dll! > "%output_file%"

:: Search for red4ext framework mod DLL files and check their versions
set "dll_files=RED4ext.dll ArchiveXL.dll TweakXL.dll Codeware.dll"
set "dll_not_found="

for %%D in (%dll_files%) do (
    set "dll_version="
    set "dll_found="
    for /R "%CYBERPUNKDIR%\red4ext" %%F in ("*%%D") do (
        for /f "delims=" %%a in ('powershell -Command "$versionInfo = Get-Command '%%F' | ForEach-Object { $_.FileVersionInfo.ProductVersion }; if ($versionInfo) { Write-Output $versionInfo }"') do (
            set "dll_version=%%a"
            set "dll_found=1"
        )
    )
    if not defined dll_found (
        if defined dll_not_found (
            set "dll_not_found=!dll_not_found!, %%D"
        ) else (
            set "dll_not_found=%%D"
        )
    ) else (
        echo %%D Version: !dll_version! >> "%output_file%"
    )
)

:: if any core mod dlls are not found, display an alert and write to the output file
if defined dll_not_found (
    echo The following core mods are not installed: %dll_not_found% >> "%output_file%"
)

:: Parse through all files ending with .log, excluding those with .number.log pattern
for /R "%CYBERPUNKDIR%" %%F in (*.log) do (
    set "filename=%%~nxF"
    setlocal enabledelayedexpansion
    set "exclude=false"

    REM Check if the file name contains two dots
    echo "!filename!" | findstr /R /C:".*\..*\.." >nul
    if !errorlevel! equ 0 (
        set "exclude=true"
    )

    REM Process non-excluded log files
    if "!exclude!"=="false" (
        for /F "delims=" %%L in ('findstr /I "exception error failed" "%%F"') do (
            echo Fault found in: %%~nxF "%%L" >> "%output_file%"
        )
    )

    endlocal
	echo Daemons uploaded successfully, data found
)
:: Open the LOGS folder in a new File Explorer window for easy navigation and uploading to Discord
start "" "%CYBERPUNKDIR%\_LOGS"

endlocal
