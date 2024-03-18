@echo off
REM Build  phoebus product for Windows
REM Create phoebus-win.zip package - used docs created in linux package.

set "VERSION=4.7.4-SNAPSHOT"

@cd %~P0
setlocal ENABLEDELAYEDEXPANSION

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
echo Extracting the data from phoebus-linux.zip to copy doc directory and settings_template.ini
rd /s /q temp_extracted
powershell Expand-Archive -Path "phoebus-product\phoebus-linux.zip" -DestinationPath "temp_extracted" -Force

set "ZIPFOLDER=temp_extracted"
set "NEWZIP=phoebus-%VERSION%"
mkdir %NEWZIP%\lib

echo Copying all needed files to %NEWZIP%

move /Y %ZIPFOLDER%\%NEWZIP%\doc %NEWZIP%
copy %ZIPFOLDER%\%NEWZIP%\settings_template.ini %NEWZIP%
copy phoebus-product\target\lib\* %NEWZIP%\lib
copy phoebus-product\site_splash.png %NEWZIP%
copy phoebus-product\phoebus.* %NEWZIP%
copy phoebus-product\settings.* %NEWZIP%
copy phoebus-product\target\product-*jar %NEWZIP%

rd /s /q temp_extracted
rem Create new phoebus-win.zip archive

powershell Compress-Archive -Path "phoebus-%VERSION%\*" -DestinationPath ".\phoebus-product\phoebus-win.zip" -Force
rem Clean up temporary files
echo Clean up temporary files
rd /s /q temp_extracted
rd /s /q %NEWZIP%
rd /s /q phoebus-product\tmp-zip

echo All commands executed successfully
echo A new product package phoebus-win.zip has been created

