@echo off
@chcp 65001 > nul

echo.
echo ==========================================
echo 🚀 [1/5] 플러터 빌드를 시작합니다...
echo ==========================================
call flutter build apk --release

if %errorlevel% neq 0 (
    echo.
    echo ❌ 빌드 실패! 에러를 확인하세요.
    exit /b %errorlevel%
)

echo.
echo ==========================================
echo 📝 [2/5] 릴리스 노트 생성 중...
echo ==========================================

:: 1. 가장 최근 태그 찾기
:: 2>nul 은 에러 메시지를 숨기는 용도입니다 (태그가 하나도 없을 때를 대비)
for /f "delims=" %%i in ('git describe --tags --abbrev^=0 2^>nul') do set LAST_TAG=%%i

if "%LAST_TAG%"=="" (
    echo 🔹 이전 배포 태그가 없습니다. 최근 10개 커밋을 가져옵니다.
    git log -10 --pretty=format:"- %%s (%%an)" > release_notes.txt
) else (
    echo 🔹 마지막 배포 태그 [%LAST_TAG%] 이후의 변경 사항을 가져옵니다.
    git log %LAST_TAG%..HEAD --pretty=format:"- %%s (%%an)" > release_notes.txt
)

:: 2. 내용이 비어있는지 확인
for %%A in (release_notes.txt) do if %%~zA==0 (
    echo ⚠️ 변경 사항이 없습니다. "재배포"라고 적습니다.
    echo - 재배포 (변경사항 없음) > release_notes.txt
)

:: 미리보기
echo ------------------------------------------
type release_notes.txt
echo ------------------------------------------

echo.
echo ==========================================
echo 📤 [3/5] 파이어베이스 업로드 시작...
echo ==========================================

call firebase appdistribution:distribute build\app\outputs\flutter-apk\app-release.apk --app "1:237548170950:android:30f5e25176a3ca41dd31c7" --groups "morningmate" --release-notes-file release_notes.txt

if %errorlevel% neq 0 (
    echo.
    echo ❌ 업로드 실패! 작업을 중단합니다.
    exit /b %errorlevel%
)

echo.
echo ==========================================
echo 🏷️ [4/5] 새 배포 태그 생성 및 푸시...
echo ==========================================

:: 3. 새 태그 이름 만들기 (build-날짜-시간 형식)
:: 윈도우 wmic 명령어로 날짜시간 가져오기 (전세계 공통 포맷)
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set datetime=%%I
set NEW_TAG=build-%datetime:~0,8%-%datetime:~8,4%

echo 새 태그 이름: %NEW_TAG%

:: 로컬에 태그 생성
git tag %NEW_TAG%

:: 4. 깃허브(원격 저장소)에 태그 업로드 (팀원들과 공유하기 위함)
git push origin %NEW_TAG%

if %errorlevel% neq 0 (
    echo ⚠️ 태그 푸시에 실패했습니다. (권한 문제 등)
    echo 하지만 배포는 성공했으니 걱정 마세요.
) else (
    echo ✅ 태그 공유 완료! 이제 팀원들도 이 시점을 알게 됩니다.
)

:: 임시 파일 삭제
del release_notes.txt

echo.
echo ✅ [5/5] 모든 작업 완료!
pause
