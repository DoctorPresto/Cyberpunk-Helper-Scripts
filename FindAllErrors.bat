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

:: Make sure that we're inside the cyberpunk dir, if not, deploy R.A.B.I.D.S and shut down
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
if not exist "%CYBERPUNKDIR%\LOGS" mkdir "%CYBERPUNKDIR%\LOGS"

:: Set the output file path for the FilteredLogs file
set "output_file=%CYBERPUNKDIR%\LOGS\FilteredLogs.txt"

:: if there's already a FilteredLogs.txt file, clear the content so that all of the errors listed were recorded on this run this run
break > "%output_file%"

:: Set the path to the executable 
set "exe_path=%CYBERPUNKDIR%\bin\x64\Cyberpunk2077.exe"

:: Get exe version using wmic datafile command
for /f "tokens=2 delims==" %%a in ('wmic datafile where name^="!exe_path:\=\\!" get version /value') do (
    for /f "delims=" %%b in ("%%a") do set "version=%%b"
)

:: if not the current game version, yell at the user and deploy R.A.B.I.D.S.
if not "!version!"=="3.0.71.13361" (
  echo
  echo Please update the game before proceeding
  echo.
  echo Deploying Roving Autonomous Bartmoss Interface Drones....
  FOR /L %%S IN (10, -1, 1) DO (
    set /p =%%S ...!carret!<nul
    ping -n 2 127.0.0.1 > nul 2>&1
)
  goto :eof
)
:: Append version info to the output file
echo Version: !version! > "%output_file%"

:: Parse through all files ending with .log, list any lines which say exception, error, or failed as well as the name of the file they were found in
for /R "%CYBERPUNKDIR%" %%F in (*.log) do (
    for /F "delims=" %%L in ('findstr /I "exception error failed" "%%F"') do (
        echo Fault found in: %%~nxF "%%L" >> "%output_file%"
    )
	echo Daemons uploaded successfully, data found 
)
:: Open the LOGS folder in a new File Explorer window for easy naviation and uploading to discord
start "" "%CYBERPUNKDIR%\LOGS"

endlocal
