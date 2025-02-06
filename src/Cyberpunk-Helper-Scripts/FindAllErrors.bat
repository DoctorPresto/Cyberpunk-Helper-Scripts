@echo off
setlocal enabledelayedexpansion

set /p "=Establishing connection" <nul
for /L %%i in (1,1,60) do (
    set /p "=." <nul
    ping localhost -n 1 >nul
)
echo.

:: Check if we are in the cyberpunk directory or if the cyberpunk directory was dragged onto the script. Mostly stolen from Mana
if "%~1" == "" (
  pushd "%~dp0"
  set "CYBERPUNKDIR=!CD!"
  popd
) else (
  set "CYBERPUNKDIR=%~1"
)

:: Check if the script folder is set to read-only
pushd %~dp0
if %errorlevel% neq 0 (
    echo ERROR: The script folder is set to read-only.
    echo Please ensure write permissions are available and try again.
    popd
    pause
    exit /b
)
popd

echo.

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

:: ====================================================================

:: visualc redistributable version
set VC_VERSION=14.42.34433.0

:: game version (of executable)
set LATESTVERSION=3.0.78.57301

:: ====================================================================

echo.
echo Please select an option:
echo.
echo 1. Delete all log files and launch the game (you should cause your issue to happen in game, then run this script again and select option 2)
echo.
echo 2. Check for errors
echo.

set /p userOption=Enter your choice: 
if "%userOption%"=="1" (
	echo.
    echo Deleting all log files...
    for /R "%~dp0" %%G in (*.log *log.txt) do (
        del /F /Q "%%G"
    )
	echo.
    echo All log files deleted successfully.
    echo Starting Cyberpunk 2077...
    start "" "%CYBERPUNKDIR%\bin\x64\Cyberpunk2077.exe" -modded
    goto :eof
) else if "%userOption%"=="2" (
    echo Deploying Datamine
) else (
    echo Invalid option, please enter 1 or 2.
    goto START
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
:: Check if the LOGS folder already exists in the install directory, if not, create it
if not exist "%CYBERPUNKDIR%\_LOGS" mkdir "%CYBERPUNKDIR%\_LOGS"

:: Set the output file path for the FilteredLogs file
set "output_file=%CYBERPUNKDIR%\_LOGS\FilteredLogs.txt"

:: if there's already a FilteredLogs.txt file, clear the content so that all of the errors listed were recorded on this run this run
break > "%output_file%"

:: Set the path to the cyberpunk exe 
set "exe_path=%CYBERPUNKDIR%\bin\x64\Cyberpunk2077.exe"
:: Get exe version using PowerShell and capture the output
for /f "usebackq delims=" %%i in (`powershell -Command "$file = Get-Item '%exe_path%'; $version = [string]$file.VersionInfo.FileMajorPart + '.' + [string]$file.VersionInfo.FileMinorPart + '.' + [string]$file.VersionInfo.FileBuildPart + '.' + [string]$file.VersionInfo.FilePrivatePart; Write-Output $version"`) do ( set "version=%%i" )

:: if not the current game version, yell at the user and deploy R.A.B.I.D.S.
if not "!version!"=="%LATESTVERSION%" (
  echo Please update the game before proceeding. The most recent game version is 2.21 with the executable version %LATESTVERSION%
  echo.
  echo Deploying Roving Autonomous Bartmoss Interface Drones....
  FOR /L %%S IN (10, -1, 1) DO (
    set /p =%%S ...!carret!<nul
    ping -n 2 127.0.0.1 > nul 2>&1
  )
  echo Done. You can leave now.
  goto :eof
)

:: Append version info to the output file
echo Game version: !version! > "%output_file%"

:: get CET Version from the log file 
set "cet_log=%CYBERPUNKDIR%\bin\x64\plugins\cyber_engine_tweaks\cyber_engine_tweaks.log"
set "cet_version="
set "cet_found="

if exist "%cet_log%" (
    for /f "delims=" %%a in ('findstr /I /C:"CET version" "%cet_log%"') do (
        set "cet_version_line=%%a"
    )
    :: Trim the version from the line
    for /f "tokens=12 delims= " %%a in ("!cet_version_line!") do (
        set "cet_version=%%~a"
        set "cet_found=1"
    )
)

:: if CET is not found, add CET to dll_not_found
if not defined cet_found (
    if defined dll_not_found (
        set "dll_not_found=!dll_not_found!, CET"
    ) else (
        set "dll_not_found=CET"
    )
)

set "redscript_files=engine\tools\scc.exe engine\tools\scc_lib.dll engine\config\base\scripts.ini r6\config\cybercmd\scc.toml"
set "redscript_missing="

:: Check for the existence of each Redscript mod file
for %%R in (%redscript_files%) do (
    if not exist "%CYBERPUNKDIR%\%%R" (
        if defined redscript_missing (
            set "redscript_missing=!redscript_missing!, %%R"
        ) else (
            set "redscript_missing=%%R"
        )
    )
)

:: If any Redscript mod files are missing, add Redscript to the list of missing frameworks
if defined redscript_missing (
    if defined dll_not_found (
        set "dll_not_found=!dll_not_found!, Redscript"
    ) else (
        set "dll_not_found=Redscript"
    )
) 
:: Search for red4ext framework mod DLL files and check their versions
set "dll_files=RED4ext.dll ArchiveXL.dll TweakXL.dll Codeware.dll"

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
            set "dll_not_found=!dll_not_found!, %%~nD"
        ) else (
            set "dll_not_found=%%~nD"
        )
    ) else (
        echo %%~nD Version: !dll_version! >> "%output_file%"
    )
)

:: check for RHT
if exist "%CYBERPUNKDIR%\red4ext\plugins\RedHotTools\RedHotTools.dll" (
    for /f "delims=" %%a in ('powershell -Command "$versionInfo = Get-Command '%CYBERPUNKDIR%\red4ext\plugins\RedHotTools\RedHotTools.dll' | ForEach-Object { $_.FileVersionInfo.ProductVersion }; if ($versionInfo) { Write-Output $versionInfo }"') do (
        set "dll_version=%%a"
        set "dll_found=1"
    )
    if defined dll_found (
        echo RedHotTools Version: !dll_version! >> "%output_file%"
    )
)

:: if any core mod dlls or CET are not found, display an alert and write to the output file
if defined dll_not_found (
    echo The following framework mods are not detected: %dll_not_found% >> "%output_file%"
)

:: Print CET version if it was found
if defined cet_found (
    echo CET Version: !cet_version! >> "%output_file%"
)

if not defined redscript_missing (
	echo
    echo Redscript: installed correctly >> "%output_file%"
)

:: check for visualc redistributable
reg query HKEY_CLASSES_ROOT\Installer\Dependencies\VC,redist.x64,amd64,14.42,bundle /V Version | Find "%VC_VERSION%" >nul
if %errorlevel% equ 0 (
  echo Visual C++ x64 Redist %VC_VERSION% installed >> "%output_file%"
) else (
  echo. >> "%output_file%"
  echo Visual C++ x64 Redist %VC_VERSION% not installed >> "%output_file%"
  echo Please download and install the 64-bit version from Microsoft: >> "%output_file%"
  echo https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist?view=msvc-170#visual-studio-2015-2017-2019-and-2022 >> "%output_file%"
  echo. >> "%output_file%"
)


:: Parse through all files ending with .log, excluding those with .number.log pattern
echo. >> "%output_file%" 
echo ======================================================== >> "%output_file%"
echo Successfully Breached: %cyberpunkdir% >> "%output_file%"
echo The following log files have errors: >> "%output_file%"
echo ======================================================== >> "%output_file%"

for /R "%CYBERPUNKDIR%" %%F in (*.log *log.txt) do (
    set "filename=%%~nxF"
    setlocal enabledelayedexpansion
    set "exclude=false"
    
::  Check if the file name contains two dots or matches the date pattern
    echo "!filename!" | findstr /R /C:".*\..*\.." >nul
    if !errorlevel! equ 0 (
        set "exclude=true"
    ) else (
        echo "!filename!" | findstr /r /c:".*20[0-9][0-9]-[0-1][0-9]-[0-3][0-9].*" >nul
    )
    if !errorlevel! equ 0 (
        set "exclude=true"
    )

::  Process non-excluded log files
    if "!exclude!"=="false" (
        :: Initialize error flag to false
        set "has_error=false"
        :: Check for any errors in the file. If found, set error flag to true
        for /F "delims=" %%L in ('findstr /I "exception error failed" "%%F" ^| findstr /V /I /C:"Failed to create record" ^| findstr /V /I /C:"[AMM Error] Non-localized string found" ^| findstr /V /I /C:"reason: Record already exists" ^| findstr /V /I /C:"[Info]"') do (
            set "has_error=true"
        )
        
        :: If error is found, print filepath and process the error lines
        if "!has_error!"=="true" (
            echo. >> "%output_file%"
            set "relative_path=%%~dpF"
            set "relative_path=!relative_path:%CYBERPUNKDIR%=!"
            echo !relative_path:~1!%%~nxF >> "%output_file%"
            echo. >> "%output_file%"

            for /F "delims=" %%L in ('findstr /I "exception error failed" "%%F" ^| findstr /V /I /C:"Failed to create record" ^| findstr /V /I /C:"[AMM Error] Non-localized string found" ^| findstr /V /I /C:"reason: Record already exists" ^| findstr /V /I /C:"[Info]"') do (
                echo     %%L >> "%output_file%"
                echo Daemons uploaded successfully, data found
            )
        )
    )
    endlocal
)

:: Open the LOGS folder in a new File Explorer window for easy navigation and uploading to Discord
start "" "%CYBERPUNKDIR%\_LOGS"
start "" "%CYBERPUNKDIR%\_LOGS\FilteredLogs.txt"

endlocal
