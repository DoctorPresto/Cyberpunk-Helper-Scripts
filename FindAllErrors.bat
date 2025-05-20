@echo off
setlocal enabledelayedexpansion

set /p "=Establishing connection" <nul
for /L %%i in (1,1,60) do (
    set /p "=." <nul
    ping localhost -n 1 >nul
)
echo.

REM Check if we are in the cyberpunk directory or if the cyberpunk directory was dragged onto the script. Mostly stolen from Mana
if [%~1] == [] (
  pushd %~dp0
  set "CYBERPUNKDIR=!CD!"
  popd
) else (
  set "CYBERPUNKDIR=%~1"
)

REM Check if the script folder is set to read-only
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

REM if not, deploy R.A.B.I.D.S and shut down
if not exist "!CYBERPUNKDIR!\bin\x64\Cyberpunk2077.exe" (
  echo.
  echo Wake the f*ck up Samurai! This is not your Cyberpunk install directory!
  echo Either place me in your Cyberpunk 2077 folder and try again,
  echo or drag and drop it onto me from Windows Explorer.
  echo.
  echo Deploying Roving Autonomous Bartmoss Interface Drones....
  FOR /L %%S IN (10, -1, 1) DO (
    set /p =%%S ...!carret!<nul
    ping -n 2 127.0.0.1 > nul 2>&1
  )
  goto :eof
)

REM ====================================================================

REM visualc redistributable version
set VC_VERSION=14.42.34433.0

REM game version (of executable)
set LATESTVERSION=3.0.78.57301

REM ====================================================================

:START

echo.
echo Please select an option:
echo.
echo 1. Delete all log files and launch the game (you should cause your issue to happen in game, then run this script again and select option 2)
echo.
echo 2. Check for errors
echo.

set /p userOption=Enter your choice: 
if !userOption! equ 1 (
	echo.
    echo Deleting all log files...
    for /R "%~dp0" %%G in (*.log *log.txt) do (
        del /F /Q "%%G"
    )
	echo.
    echo All log files deleted successfully.
    echo Starting Cyberpunk 2077...
    start "" "!CYBERPUNKDIR!\bin\x64\Cyberpunk2077.exe" -modded
    goto :eof
) else if !userOption! equ 2 (
    echo Deploying Datamine
) else (
    echo Invalid option, please enter 1 or 2.
    goto :START
)

REM if not, deploy R.A.B.I.D.S and shut down
if not exist "!CYBERPUNKDIR!\bin\x64\Cyberpunk2077.exe" (
  echo.
  echo Wake the f*ck up Samurai! This is not your Cyberpunk install directory
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
REM Check if the LOGS folder already exists in the install directory, if not, create it
if not exist "!CYBERPUNKDIR!\_LOGS" mkdir "!CYBERPUNKDIR!\_LOGS"

REM Set the output file path for the FilteredLogs file
set "output_file=!CYBERPUNKDIR!\_LOGS\FilteredLogs.txt"

REM if there's already a FilteredLogs.txt file, clear the content so that all of the errors listed were recorded on this run this run
echo > "!output_file!"

REM Set the path to the cyberpunk exe 
set "exe_path=!CYBERPUNKDIR!\bin\x64\Cyberpunk2077.exe"
REM Get exe version using PowerShell and capture the output
for /f "usebackq delims=" %%i in (`powershell -Command "$file = Get-Item '!exe_path!'; $version = [string]$file.VersionInfo.FileMajorPart + '.' + [string]$file.VersionInfo.FileMinorPart + '.' + [string]$file.VersionInfo.FileBuildPart + '.' + [string]$file.VersionInfo.FilePrivatePart; Write-Output $version"`) do ( set "version=%%i" )

REM if not the current game version, yell at the user and deploy R.A.B.I.D.S.
if not "!version!"=="!LATESTVERSION!" (
  echo Please update the game before proceeding. The most recent game version is 2.21 with the executable version !LATESTVERSION!
  echo.
  echo Deploying Roving Autonomous Bartmoss Interface Drones....
  FOR /L %%S IN (10, -1, 1) DO (
    set /p =%%S ...!carret!<nul
    ping -n 2 127.0.0.1 > nul 2>&1
  )
  echo Done. You can leave now.
  goto :eof
)

REM Append version info to the output file
echo Game version: !version! > "!output_file!"

REM get CET Version from the log file 
set "cet_log=!CYBERPUNKDIR!\bin\x64\plugins\cyber_engine_tweaks\cyber_engine_tweaks.log"
set "cet_version="
set "cet_found="

if exist "!cet_log!" (
    for /f "delims=" %%a in ('findstr /I /C:"CET version" "!cet_log!"') do (
        set "cet_version_line=%%a"
    )
    REM Trim the version from the line
    for /f "tokens=12 delims= " %%a in ("!cet_version_line!") do (
        set "cet_version=%%~a"
        set cet_found=1
    )
)

REM if CET is not found, add CET to dll_not_found
if not defined cet_found (
    if defined dll_not_found (
        set "dll_not_found=!dll_not_found!, CET"
    ) else (
        set "dll_not_found=CET"
    )
)

set "redscript_files=engine\tools\scc.exe engine\tools\scc_lib.dll engine\config\base\scripts.ini r6\config\cybercmd\scc.toml"
set "redscript_missing="

REM Check for the existence of each Redscript mod file
for %%R in (!redscript_files!) do (
    if not exist "!CYBERPUNKDIR!\%%R" (
        if defined redscript_missing (
            set "redscript_missing=!redscript_files!, %%R"
        ) else (
            set "redscript_missing=%%R"
        )
    )
)

REM If any Redscript mod files are missing, add Redscript to the list of missing frameworks
if defined redscript_missing (
    if defined dll_not_found (
        set "dll_not_found=!dll_not_found!, Redscript"
    ) else (
        set "dll_not_found=Redscript"
    )
) 

REM Search for red4ext framework mod DLL files and check their versions
set "dll_files=RED4ext.dll ArchiveXL.dll TweakXL.dll Codeware.dll"

for %%D in (!dll_files!) do (
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

REM check for RHT
if exist "%CYBERPUNKDIR%\red4ext\plugins\RedHotTools\RedHotTools.dll" (
    for /f "delims=" %%a in ('powershell -Command "$versionInfo = Get-Command '%CYBERPUNKDIR%\red4ext\plugins\RedHotTools\RedHotTools.dll' | ForEach-Object { $_.FileVersionInfo.ProductVersion }; if ($versionInfo) { Write-Output $versionInfo }"') do (
        set "dll_version=%%a"
        set "dll_found=1"
    )
    if defined dll_found (
        echo RedHotTools Version: !dll_version! >> "%output_file%"
    )
)

REM if any core mod dlls or CET are not found, display an alert and write to the output file
if defined dll_not_found (
    echo The following framework mods are not detected: !dll_not_found! >> "%output_file%"
)

REM Print CET version if it was found
if defined cet_found (
    echo CET Version: !cet_version! >> "%output_file%"
)

if not defined redscript_missing (
  echo. >> "%output_file%"
  echo Redscript: installed correctly >> "%output_file%"
)

call :CheckVCVersion "!VC_VERSION!"

REM Parse through all files ending with .log, excluding those with .number.log pattern
echo. >> "%output_file%" 
echo ======================================================== >> "%output_file%"
echo Successfully Breached: !CYBERPUNKDIR! >> "%output_file%"
echo The following log files have errors: >> "%output_file%"
echo ======================================================== >> "%output_file%"

for /R "!CYBERPUNKDIR!" %%F in (*.log *log.txt) do (
    set "filename=%%~nxF"
    setlocal enabledelayedexpansion
    set exclude=false
    
REM  Check if the file name contains two dots or matches the date pattern
    echo "!filename!" | findstr /R /C:".*\..*\.." >nul
    if !errorlevel! equ 0 (
        set exclude=true
    ) else (
        echo "!filename!" | findstr /r /c:".*20[0-9][0-9]-[0-1][0-9]-[0-3][0-9].*" >nul
    )
    if !errorlevel! equ 0 (
        set exclude=true
    )

REM  Process non-excluded log files
    if "!exclude!"=="false" (
        REM Initialize error flag to false
        set has_error=false
        REM Check for any errors in the file. If found, set error flag to true
        for /F "delims=" %%L in ('findstr /I "exception error failed" "%%F" ^| findstr /V /I /C:"Failed to create record" ^| findstr /V /I /C:"[AMM Error] Non-localized string found" ^| findstr /V /I /C:"reason: Record already exists" ^| findstr /V /I /C:"[Info]"') do (
            set has_error=true
        )
        
        REM If error is found, print filepath and process the error lines
        if "!has_error!"=="true" (
            echo. >> "%output_file%"
            set "relative_path=%%~dpF"
            set "relative_path=!relative_path:!CYBERPUNKDIR!=!"
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



REM Open the LOGS folder in a new File Explorer window for easy navigation and uploading to Discord
start "" "%CYBERPUNKDIR%\_LOGS"
start "" "%CYBERPUNKDIR%\_LOGS\FilteredLogs.txt"

endlocal

goto :eof



:CheckVCVersion
REM Checks if the installed VC++ Redistributable version is >= <MinVersion>.
REM Returns 0 if OK, 1 if too old or not found.
    setlocal
    set "MIN_VERSION=%~1"
    
    REM Parse the minimum version into components
    for /f "tokens=1-4 delims=." %%A in ("%MIN_VERSION%") do (
        set MIN_MAJOR=%%A
        set MIN_MINOR=%%B
        set MIN_BUILD=%%C
        set MIN_REVISION=%%D
    )

  
  set "INST_VERSION="
  for /f "delims=" %%A in ('powershell -noprofile -command "$v = (Get-ChildItem HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*,HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | ForEach-Object { if ($_.GetValue('DisplayName') -match '^Microsoft Visual C\+\+.*Redistributable.*x64.*- ([\d\.]+)') { $Matches[1] } } | Sort-Object -Descending | Select-Object -First 1); if ($v) { $v } else { '' }"') do set "INST_VERSION=%%A"

  if not defined INST_VERSION (        

      echo. >> "%output_file%"
      echo Visual C++ x64 Redist %VC_VERSION% not installed >> "%output_file%"
      echo Please download and install the 64-bit version from Microsoft: >> "%output_file%"
      echo https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist?view=msvc-170#visual-studio-2015-2017-2019-and-2022 >> "%output_file%"
      echo. >> "%output_file%"
      endlocal
      
      goto :eof      
  )
  
    REM Parse installed version into components
    for /f "tokens=1-4 delims=." %%A in ("%INST_VERSION%") do (
        set INST_MAJOR=%%A
        set INST_MINOR=%%B
        set INST_BUILD=%%C
        set INST_REVISION=%%D
    )

    REM Compare version components numerically
    if "%INST_MAJOR%" gtr "%MIN_MAJOR%" (
        set VERSION_OK=1
    ) else if "%INST_MAJOR%" equ "%MIN_MAJOR%" (
        if "%INST_MINOR%" gtr "%MIN_MINOR%" (
            set VERSION_OK=1
        ) else if "%INST_MINOR%" equ "%MIN_MINOR%" (
            if "%INST_BUILD%" gtr "%MIN_BUILD%" (
                set VERSION_OK=1
            ) else if "%INST_BUILD%" equ "%MIN_BUILD%" (
                if "%INST_REVISION%" geq "%MIN_REVISION%" (
                    set VERSION_OK=1
                )
            )
        )
    )

    if defined VERSION_OK (
        echo Visual C++ x64 Redist %VC_VERSION% installed ✔ Required: %MIN_VERSION% >> "%output_file%"        
    ) else (    
        echo. >> "%output_file%"
        echo Visual C++ x64 Redist %VC_VERSION% installed ✖ Required: %MIN_VERSION% >> "%output_file%"
        echo Please download and install the 64-bit version from Microsoft: >> "%output_file%"
        echo https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist?view=msvc-170#visual-studio-2015-2017-2019-and-2022 >> "%output_file%"
        echo. >> "%output_file%"        
    )
    endlocal
    goto :eof
    
