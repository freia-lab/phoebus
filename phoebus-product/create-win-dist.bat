@echo off
REM Build  phoebus product for Windows.
REM Run this batch script from the top directory: phoebus_product\create-win-dist.bat
REM Create phoebus-win.zip package - used docs created in linux package.
REM Requires command line tool to make a zip archive because the file produced by 
REM PowerShell command Compress-Archive is not correctly unpacked by the CSS update module.

set "VERSION=4.7.4-SNAPSHOT"

@cd %~P0
setlocal ENABLEDELAYEDEXPANSION

rem echo %~P0
if exist "%~P0phoebus-win.zip" (
    del /q "%~P0phoebus-win.zip"
    echo Deleted the old "%~P0phoebus-win.zip"
)

rem Get today's date in YYYY-MM-DD format
for /f "tokens=2-4 delims=/ " %%a in ('date /t') do (
    set "MM=%%a"
    set "DD=%%b"
    set "YYYY=%%c"
)

set "TODAY=%YYYY%-%MM%-%DD%"
rem Create settings.ini file
(
    echo # Self-update
    echo org.phoebus.applications.update/current_version=%TODAY% 23:59
    echo org.phoebus.applications.update/update_url=https://freia.physics.uu.se/CSS/phoebus/phoebus-$(arch^).zip
) > settings.ini


rem Check if the settings.ini file was created successfully
if not exist settings.ini (
    echo Error: Failed to create settings.ini file
    exit /b 1
)

@cd ..

echo Running mvn clean verify -f dependencies\pom.xml...
call mvn clean verify -f dependencies\pom.xml

rem Check if the previous command was successful
if %ERRORLEVEL% NEQ 0 (
    echo Error occurred while executing mvn clean verify -f dependencies\pom.xml
    exit /b %ERRORLEVEL%
)

rem Execute mvn -DskipTests clean install command
echo Running mvn -DskipTests clean install...
call mvn -DskipTests clean install

rem Check if the previous command was successful
if %ERRORLEVEL% NEQ 0 (
    echo Error occurred while executing mvn -DskipTests clean install
    exit /b %ERRORLEVEL%
)

rem Extract the doc folder from phoebus-linux.zip

set "ZIPFOLDER=temp_extracted"
set "NEWZIP=phoebus-%VERSION%"
rd /s /q %ZIPFOLDER%
set "zip_cmd=C:\Program Files\7-Zip\7z.exe"
if exist "%zip_cmd%" (
    echo Extracting the data from phoebus-linux.zip to copy doc directory and settings_template.ini
    "%zip_cmd%" x -tzip "phoebus-product\phoebus-linux.zip" -o"%ZIPFOLDER%"
)

rem powershell Expand-Archive -Path "phoebus-product\phoebus-linux.zip" -DestinationPath "temp_extracted" -Force

mkdir %NEWZIP%\lib

echo Copying all needed files to %NEWZIP%

move /Y %ZIPFOLDER%\%NEWZIP%\doc %NEWZIP%
copy %ZIPFOLDER%\%NEWZIP%\settings_template.ini %NEWZIP%
copy phoebus-product\target\lib\* %NEWZIP%\lib
copy phoebus-product\site_splash.png %NEWZIP%
copy phoebus-product\phoebus.* %NEWZIP%
copy phoebus-product\settings.* %NEWZIP%
copy phoebus-product\target\product-*jar %NEWZIP%

echo removing %ZIPFOLDER%
rd /s /q %ZIPFOLDER%

if not exist "%zip_cmd%" (
 	echo 7-zip program not installed. Install it and run the script again
 	echo or send .\phoebus-%VERSION% to commpressed folder and rename it to phoebus-win.zip
	pause
 	exit /b
rem Compress-Archive creates the archive that can't be properly read by Control System Studio
rem powershell Compress-Archive -Path ".\phoebus-%VERSION%" -DestinationPath ".\phoebus-product\phoebus-win.zip" -Force
)

rem Create new phoebus-win.zip archive
echo compressing ".\phoebus-%VERSION%" into ".\phoebus-product\phoebus-win.zip" 
"%zip_cmd%" a -tzip ".\phoebus-product\phoebus-win.zip" ".\phoebus-%VERSION%"

echo removing %NEWZIP% directory
rd /s /q %NEWZIP%
echo All commands executed successfully
echo A new product package phoebus-win.zip has been created


