@echo off
setlocal enabledelayedexpansion

:: --- 1. Dynamically figure out Mod Name based on folder name ---
:: E.g., if folder is "AD3D_LightSolutionMod", MOD_NAME becomes "AD3D_LightSolution"
for %%I in (.) do set "FOLDER_NAME=%%~nxI"
:: Replace "Mod" with nothing
set "MOD_NAME=%FOLDER_NAME:Mod=%"

echo [INFO] Running release for Mod: %MOD_NAME%

:: --- 2. Setup dynamic paths ---
set "REPO_DIR=%CD%"
set "PROJECT_FILE=E:\Mods\Subnautica\%MOD_NAME%\%MOD_NAME%.csproj"
set "ZIP_SN=E:\Mods\Subnautica\Download\SN\%MOD_NAME%.SN.zip"
set "ZIP_BZ=E:\Mods\Subnautica\Download\BZ\%MOD_NAME%.BZ.zip"

:: --- 3. Extract Version from .csproj ---
if not exist "%PROJECT_FILE%" (
    echo [ERROR] Project file not found: %PROJECT_FILE%
    pause
    exit /b 1
)

set "MOD_VERSION="
:: Uses delims logic to reliably pull out version from <Version>number</Version>
for /f "tokens=2 delims=>" %%a in ('findstr /i "<Version>" "%PROJECT_FILE%"') do (
    for /f "tokens=1 delims=<" %%b in ("%%a") do (
        set "MOD_VERSION=%%b"
    )
)

if "%MOD_VERSION%"=="" (
    echo [ERROR] Could not find ^<Version^> tag in %PROJECT_FILE%
    pause
    exit /b 1
)

set "TAG_NAME=v%MOD_VERSION%"
echo [INFO] Found project version: %TAG_NAME%

:: --- 4. Check if tag already exists in the repo ---
git rev-parse "%TAG_NAME%" >nul 2>&1
if %errorlevel% equ 0 (
    echo [INFO] Tag %TAG_NAME% already exists in this repository. 
    echo [INFO] Assuming release is already published. No action needed.
    pause
    exit /b 0
)

echo [INFO] Tag %TAG_NAME% is new. Preparing release...

:: --- 5. Verify the generated zip files exist ---
if not exist "%ZIP_SN%" (
    echo [ERROR] SN Zip file not found: %ZIP_SN%
    pause
    exit /b 1
)
if not exist "%ZIP_BZ%" (
    echo [ERROR] BZ Zip file not found: %ZIP_BZ%
    pause
    exit /b 1
)

:: --- 6. Commit, Tag and Push ---
echo [INFO] Creating git tag %TAG_NAME%...
git tag "%TAG_NAME%"
if %errorlevel% neq 0 (
    echo [ERROR] Failed to create git tag.
    pause
    exit /b 1
)

echo [INFO] Pushing tag to remote...
git push origin "%TAG_NAME%"
if %errorlevel% neq 0 (
    echo [ERROR] Failed to push git tag.
    pause
    exit /b 1
)

:: --- 7. Create GitHub Release via GitHub CLI ---
echo [INFO] Creating GitHub release and uploading .zip files...
gh release create "%TAG_NAME%" "%ZIP_SN%" "%ZIP_BZ%" --title "Release %TAG_NAME%" --generate-notes
if %errorlevel% neq 0 (
    echo [ERROR] Failed to create GitHub release. Make sure GitHub CLI ^(gh^) is authenticated.
    pause
    exit /b 1
)

echo [SUCCESS] Release %TAG_NAME% published successfully!
pause
