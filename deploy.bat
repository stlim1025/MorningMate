@echo off

echo.
echo ==========================================
echo [1/5] Calculating Build Version...
echo ==========================================

for /f "delims=" %%i in ('git rev-list --count HEAD') do set BUILD_NUMBER=%%i

set /a BUILD_NUMBER=%BUILD_NUMBER%

echo Current Build Number: %BUILD_NUMBER%

echo.
echo ==========================================
echo [2/5] Flutter Build Start...
echo ==========================================

call flutter build apk --release --build-name=1.0.%BUILD_NUMBER%

if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Build Failed! Check errors above.
    exit /b %errorlevel%
)

echo.
echo ==========================================
echo [3/5] Generaging Release Notes...
echo ==========================================

for /f "delims=" %%i in ('git describe --tags --abbrev^=0 2^>nul') do set LAST_TAG=%%i

if "%LAST_TAG%"=="" (
    echo [INFO] No previous tags. Fetching last 10 commits.
    git log -10 --pretty=format:"- %%s (%%an)" > release_notes.txt
) else (
    echo [INFO] Fetching changes since [%LAST_TAG%]
    git log %LAST_TAG%..HEAD --pretty=format:"- %%s (%%an)" > release_notes.txt
)

for %%A in (release_notes.txt) do if %%~zA==0 (
    echo - Re-deploy (No changes) > release_notes.txt
)

echo ------------------------------------------
type release_notes.txt
echo ------------------------------------------

echo.
echo ==========================================
echo [4/5] Uploading to Firebase...
echo ==========================================

call firebase appdistribution:distribute build\app\outputs\flutter-apk\app-release.apk --app "1:237548170950:android:30f5e25176a3ca41dd31c7" --groups "morningmate" --release-notes-file release_notes.txt

if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Upload Failed!
    exit /b %errorlevel%
)

echo.
echo ==========================================
echo [5/5] Creating New Git Tag...
echo ==========================================

for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set datetime=%%I
set NEW_TAG=v1.0.%BUILD_NUMBER%

echo New Tag: %NEW_TAG%

git tag %NEW_TAG%
git push origin %NEW_TAG%

del release_notes.txt

echo.
echo ==========================================
echo [Success] Deployed Version: 1.0.0 (%BUILD_NUMBER%)
echo ==========================================
pause
