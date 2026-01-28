@echo off

echo.
echo ==========================================
echo [1/5] Calculating Build Version...
echo ==========================================

:: 1. 깃 커밋 총 개수를 가져와서 BUILD_NUMBER 변수에 저장
for /f "delims=" %%i in ('git rev-list --count HEAD') do set BUILD_NUMBER=%%i

:: 2. 혹시 몰라서 +1000을 해줍니다 (기존 1보다 무조건 크게 만들기 위해)
:: 필요 없으면 set /a BUILD_NUMBER=%BUILD_NUMBER% 만 해도 됩니다.
set /a BUILD_NUMBER=%BUILD_NUMBER% + 1000

echo Current Build Number: %BUILD_NUMBER%

echo.
echo ==========================================
echo [2/5] Flutter Build Start...
echo ==========================================

:: 핵심! --build-number 옵션으로 버전을 덮어씌웁니다.
:: --build-name 옵션을 쓰면 "1.0.0" 부분도 바꿀 수 있습니다. (예: --build-name=1.0.%BUILD_NUMBER%)
call flutter build apk --release --build-number=%BUILD_NUMBER%

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

:: 앱 ID 확인 필수!
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
