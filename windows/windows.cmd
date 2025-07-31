@echo off
SETLOCAL ENABLEDELAYEDEXPANSION
chcp 65001 >nul
title GLAUTUDE-Windows-1.1

SET "SCRIPT_PATH=%~f0"
ECHO "%SCRIPT_PATH%" | findstr /I "%TEMP%" >nul
IF NOT ERRORLEVEL 1 (
    ECHO [ERROR] You are running the script from your TEMP folder!
    ECHO That is dangerous. Please move it to your Desktop or another folder.
    PAUSE
    EXIT /B
)

REM --- Configuration ---
SET "SEARCH_RESULT_LIMIT=5"
SET "BIN_DIR=%~dp0bin"
SET "YTDLP_EXE=%BIN_DIR%\yt-dlp.exe"
SET "MPV_URL=https://github.com/zhongfly/mpv-winbuild/releases/download/2025-07-30-a6f3236/mpv-x86_64-20250730-git-a6f3236.7z"
SET "MPV_ARCHIVE=%BIN_DIR%\mpv.7z"
SET "MPV_EXE=%BIN_DIR%\mpv.com"
SET "SEVENZ_EXE=%BIN_DIR%\7z.exe"
SET "YTDLP_ZIP_URL=https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_win.zip"
SET "YTDLP_ZIP_PATH=%BIN_DIR%\yt-dlp.zip"
SET "COLORTOOL_URL=https://github.com/microsoft/terminal/releases/download/1904.29002/ColorTool.zip"
SET "COLORTOOL_ZIP=%BIN_DIR%\ColorTool.zip"
SET "COLORTOOL_DIR=%BIN_DIR%\ColorTool"
SET "COLORTOOL_EXE=%COLORTOOL_DIR%\ColorTool.exe"
SET "FFMPEG_ZIP_URL=https://github.com/BtbN/FFmpeg-Builds/releases/latest/download/ffmpeg-n7.1-latest-win64-lgpl-7.1.zip"
SET "FFMPEG_ZIP_PATH=%BIN_DIR%\ffmpeg.zip"
SET "FFMPEG_DIR=%BIN_DIR%\ffmpeg"
SET "FFMPEG_EXE=%FFMPEG_DIR%\ffmpeg.exe"
SET "PATH=%BIN_DIR%;%FFMPEG_DIR%;%PATH%"
SET "ZIP=ffmpeg.zip"
SET "EXTRACTDIR=%CD%\bin\ffmpeg"

REM --- Dependency Setup ---
CALL :SETUP_DEPENDENCIES
IF ERRORLEVEL 1 GOTO :ABORT_PROGRAM

GOTO :MAIN_MENU

:SETUP_DEPENDENCIES
ECHO [INFO] Checking...

IF NOT EXIST "%BIN_DIR%" (
    ECHO [INFO] Creating BIN_DIR...
    MD "%BIN_DIR%"
)

REM --- 7z (from OptimizedToolsPlusPlus) ---
IF NOT EXIST "%SEVENZ_EXE%" (
    ECHO [ERR] 7z.exe not found. Downloading...
    curl -L -o "%SEVENZ_EXE%" "https://github.com/NammIsADev/OptimizedToolsPlusPlus/raw/main-development/bin/7z.exe"
)

IF NOT EXIST "%SEVENZ_EXE%" (
    ECHO [ERR] 7z.exe still not found after download!
    EXIT /B 1
)
ECHO [INFO] 7zip-cli download successfully.

REM --- yt-dlp ---
IF NOT EXIST "%YTDLP_EXE%" (
    ECHO [ERR] yt-dlp not found. Downloading ZIP...
    curl -L -o "%YTDLP_ZIP_PATH%" "%YTDLP_ZIP_URL%"
    IF ERRORLEVEL 1 (
        ECHO [ERR] yt-dlp ZIP download failed.
        EXIT /B 1
    )

    "%SEVENZ_EXE%" x "%YTDLP_ZIP_PATH%" -o"%BIN_DIR%" -y >nul

    IF NOT EXIST "%YTDLP_EXE%" (
        ECHO [ERR] yt-dlp.exe not found after extraction!
        EXIT /B 1
    )

    ECHO [INFO] yt-dlp extracted successfully.
    DEL "%YTDLP_ZIP_PATH%" >nul
)

REM --- Validate yt-dlp ---
"%YTDLP_EXE%" --version >nul 2>&1
IF ERRORLEVEL 1 (
    ECHO [ERR] yt-dlp.exe is broken. Re-downloading...
    DEL /F /Q "%YTDLP_EXE%"
    GOTO :SETUP_DEPENDENCIES
)

REM --- MPV setup ---
IF NOT EXIST "%MPV_EXE%" (
    ECHO [INFO] MPV not found. Downloading...
    curl -L -o "%MPV_ARCHIVE%" "%MPV_URL%" >nul 2>&1

    IF EXIST "%MPV_ARCHIVE%" (
        ECHO [INFO] Extracting MPV...
        "%BIN_DIR%\7z.exe" x -y "%MPV_ARCHIVE%" -o"%BIN_DIR%" >nul 2>&1

        IF EXIST "%MPV_EXE%" (
            ECHO [OK] MPV setup complete.
        ) ELSE (
            ECHO [ERR] MPV setup failed — mpv.exe still missing
            GOTO :fail
        )
    ) ELSE (
        ECHO [ERR] MPV archive download failed.
        GOTO :fail
    )
)

REM --- ColorTool (optional but recommended) ---
IF NOT EXIST "%COLORTOOL_EXE%" (
    ECHO [INFO] Downloading Microsoft ColorTool...
    curl -L -o "%COLORTOOL_ZIP%" "%COLORTOOL_URL%"
    IF ERRORLEVEL 1 EXIT /B 1

    "%SEVENZ_EXE%" x "%COLORTOOL_ZIP%" -o"%COLORTOOL_DIR%" -y >nul
    DEL "%COLORTOOL_ZIP%" >nul
)

REM --- FFmpeg Setup ---
IF NOT EXIST "%FFMPEG_EXE%" (
    ECHO [INFO] FFmpeg not found. Downloading ZIP...
    curl -L -o "%FFMPEG_ZIP_PATH%" "%FFMPEG_ZIP_URL%"
    IF ERRORLEVEL 1 (
        ECHO [ERR] Failed to download FFmpeg.
        EXIT /B 1
    )

    REM Use delayed expansion to safely assign and use variables
    SETLOCAL ENABLEDELAYEDEXPANSION

    SET "FFMPEG_TMP_DIR_LOCAL=%FFMPEG_DIR%\_tmp"
    IF EXIST "!FFMPEG_TMP_DIR_LOCAL!" RMDIR /S /Q "!FFMPEG_TMP_DIR_LOCAL!" >nul 2>&1
    MD "!FFMPEG_TMP_DIR_LOCAL!" >nul 2>&1

    REM Extract zip to temp folder
    "%SEVENZ_EXE%" x "%FFMPEG_ZIP_PATH%" -o"!FFMPEG_TMP_DIR_LOCAL!" -y >nul

    REM Find ffmpeg-* folder inside temp
    SET "FFMPEG_SUBFOLDER="
    FOR /D %%D IN ("!FFMPEG_TMP_DIR_LOCAL!\ffmpeg-*") DO (
        SET "FFMPEG_SUBFOLDER=%%D"
    )

    IF NOT DEFINED FFMPEG_SUBFOLDER (
        ENDLOCAL
        ECHO [ERR] Failed to locate ffmpeg-* folder after extraction.
        RMDIR /S /Q "%FFMPEG_TMP_DIR_LOCAL%" >nul 2>&1
        EXIT /B 1
    )

    IF NOT EXIST "%FFMPEG_DIR%" MD "%FFMPEG_DIR%"

    ECHO [INFO] Moving FFmpeg binaries to %FFMPEG_DIR%...
    XCOPY "!FFMPEG_SUBFOLDER!\bin\*" "%FFMPEG_DIR%\" /E /Y /I >nul

    ENDLOCAL

    REM Cleanup and verify
    RMDIR /S /Q "%FFMPEG_DIR%\_tmp" >nul 2>&1
    DEL /F /Q "%FFMPEG_ZIP_PATH%" >nul 2>&1

    IF NOT EXIST "%FFMPEG_EXE%" (
        ECHO [ERR] FFmpeg setup failed — ffmpeg.exe still missing!
        EXIT /B 1
    )

    ECHO [INFO] FFmpeg successfully installed.
)

ECHO [WORK-DONE] Setup complete.
:: --- update check ---
SETLOCAL ENABLEDELAYEDEXPANSION
SET "CUR_VER=1.1-beta"
SET "VER_URL=https://raw.githubusercontent.com/NammIsADev/glautude/main/update/version.txt"

curl -s -o "%TEMP%\latest_ver.txt" "%VER_URL%" >nul 2>&1
IF EXIST "%TEMP%\latest_ver.txt" (
    SET /P LATEST_VER=<"%TEMP%\latest_ver.txt"
    IF NOT "!LATEST_VER!"=="%CUR_VER%" (
        ECHO.
        ECHO [UPDATE] New version available: !LATEST_VER!
        ECHO [UPDATE] Current version: %CUR_VER%
        ECHO [UPDATE] Visit: https://github.com/NammIsADev/glautude
    ) ELSE (
        ECHO [OK] You are using the latest version (%CUR_VER%)
    )
    DEL "%TEMP%\latest_ver.txt"
) ELSE (
    ECHO [ERR] Failed to check for updates.
)
ENDLOCAL

SET "PATH=%BIN_DIR%;%FFMPEG_DIR%;%PATH%"
CALL :LOGO
ECHO.
ECHO [^^!] WARNING: For best visual experience, use Windows Terminal.
ECHO     This software may patch your legacy console color table.
ECHO     Alternatively, install Windows Terminal from the Microsoft Store.
ECHO.
IF EXIST "%COLORTOOL_EXE%" (
    ECHO     ColorTool detected. Applying safe dark theme...
    "%COLORTOOL_EXE%" -b Campbell -d >nul 2>&1
)
ping -n 4 127.0.0.1 >nul
mode con: cols=120 lines=30

EXIT /B 0

:LOGO
CLS
color 07
ECHO.
ECHO  ██████╗ ██╗      █████╗ ██╗   ██╗████████╗██╗   ██╗██████╗ ███████╗
ECHO ██╔════╝ ██║     ██╔══██╗██║   ██║╚══██╔══╝██║   ██║██╔══██╗██╔════╝
ECHO ██║  ███╗██║     ███████║██║   ██║   ██║   ██║   ██║██║  ██║█████╗  
ECHO ██║   ██║██║     ██╔══██║██║   ██║   ██║   ██║   ██║██║  ██║██╔══╝  
ECHO ╚██████╔╝███████╗██║  ██║╚██████╔╝   ██║   ╚██████╔╝██████╔╝███████╗
ECHO  ╚═════╝ ╚══════╝╚═╝  ╚═╝ ╚═════╝    ╚═╝    ╚═════╝ ╚═════╝ ╚══════╝
ECHO -------------------------------------------------------------------
ECHO              GLAUTUDE - Powered by mpv and yt-dlp
ECHO -------------------------------------------------------------------
ECHO.
GOTO :EOF

:MAIN_MENU
CALL :LOGO
ECHO.
echo Conhost and Command Prompt have been deprecated. Use Windows Terminal to get best experience.
echo You can still using Command Prompt/Conhost, but you will get a poor experience.
ECHO Version: 1.1-beta-windows
ECHO.
ECHO [1] Play video/audio by Youtube URL
ECHO [2] Search YouTube Video
ECHO [3] Clear Temp (recommended before playback)
ECHO [4] Exit
ECHO.
SET /P "MENU_CHOICE=Select an option [1-4]: "

IF "%MENU_CHOICE%"=="1" GOTO :PASTE_URL
IF "%MENU_CHOICE%"=="2" GOTO :SEARCH_VIDEO
IF "%MENU_CHOICE%"=="3" GOTO :CLEAR-ALL-TEMP
IF "%MENU_CHOICE%"=="4" GOTO :EOF

ECHO Invalid choice.
TIMEOUT /T 1 >nul
GOTO :MAIN_MENU

:PASTE_URL
CLS
ECHO Please wait... Cleaning old video temp...
CALL :CLEANUP_TEMP
ECHO Checking... Ok.
ECHO Done.
ECHO You selected: Play video by Youtube URL
ECHO.
SET /P "YOUTUBE_URL=Enter Youtube URL: "
IF "%YOUTUBE_URL%"=="" GOTO :MAIN_MENU

REM === Display only unique MP4 formats ===
CALL :SHOW_MP4_FORMATS

REM === Audio only option ===
SET "AUDIO_ONLY="
ECHO.
CHOICE /M "Audio only"
IF ERRORLEVEL 2 (
    SET "AUDIO_ONLY="
) ELSE (
    SET "AUDIO_ONLY=--audio-only"
)

REM === Video quality option ===
ECHO.
SET "VIDEO_QUALITY="
SET /P "VIDEO_QUALITY=Enter format code for MP4/3 quality (e.g. 137 for 1080p, leave blank for maximum quality): "

REM === Playback logic ===
SET "OUTPUT_PATH=%TEMP%\yt_temp_play.mp4"
IF EXIST "%OUTPUT_PATH%" DEL /F /Q "%OUTPUT_PATH%"

IF NOT "%AUDIO_ONLY%"=="" (
    "%YTDLP_EXE%" --merge-output-format mp4 -f "bestaudio[ext=m4a]" -o "%OUTPUT_PATH%" "%YOUTUBE_URL%"
) ELSE IF NOT "%VIDEO_QUALITY%"=="" (
    "%YTDLP_EXE%" --merge-output-format mp4 -f "%VIDEO_QUALITY%+bestaudio[ext=m4a]" -o "%OUTPUT_PATH%" "%YOUTUBE_URL%"
) ELSE (
    "%YTDLP_EXE%" --merge-output-format mp4 -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]" -o "%OUTPUT_PATH%" "%YOUTUBE_URL%"
)


IF EXIST "%OUTPUT_PATH%" (
    CLS
    ECHO Starting... ok.
    ECHO Rendering...
    ECHO -----------------------------------------------------
	ECHO This will open a new window because mpv rendering.
    start /wait "" "%MPV_EXE%" "%OUTPUT_PATH%" --vo=tct --no-config --terminal --really-quiet
    ECHO -----------------------------------------------------
    CALL :CLEANUP_TEMP
    ECHO Done.
    PAUSE
) ELSE (
    ECHO [ERR] Download or playback failed!
    CALL :CLEANUP_TEMP
    PAUSE
)
GOTO :MAIN_MENU

:SEARCH_VIDEO
CLS
ECHO Please wait... Cleaning old video temp...
CALL :CLEANUP_TEMP
ECHO Checking... Ok.
ECHO Done.
ECHO You selected: Search Youtube Video
ECHO.
SET /P "SEARCH_QUERY=Enter keywords: "
IF "%SEARCH_QUERY%"=="" GOTO :MAIN_MENU

SETLOCAL ENABLEDELAYEDEXPANSION
SET /A INDEX=0
SET "TMPFILE=%TEMP%\yt_search.tmp"
DEL /F /Q "!TMPFILE!" 2>nul

"%YTDLP_EXE%" --flat-playlist --print "%%(title).70s|%%(webpage_url)s" "ytsearch%SEARCH_RESULT_LIMIT%:%SEARCH_QUERY%" > "!TMPFILE!" 2>nul

FOR /F "usebackq tokens=1,2 delims=|" %%A IN ("!TMPFILE!") DO (
    SET /A INDEX+=1
    SET "TITLE_!INDEX!=%%A"
    SET "URL_!INDEX!=%%B"
    ECHO [!INDEX!] %%A
)

IF !INDEX! EQU 0 (
    ECHO No results found.
    TIMEOUT /T 2 >nul
    ENDLOCAL
    GOTO :MAIN_MENU
)

:CHOOSE_RESULT
ECHO.
SET /P "CHOICE=Pick a video [1-!INDEX!] or 0 to cancel: "
IF "!CHOICE!"=="0" (
    ENDLOCAL
    GOTO :MAIN_MENU
)

IF "!CHOICE!" GEQ "1" IF "!CHOICE!" LEQ "!INDEX!" (
    SET "TMP_SEL_FILE=%TEMP%\yt_selected_url.txt"
    DEL /F /Q "!TMP_SEL_FILE!" >nul 2>&1
    SET /A LINE_NUM=0

    FOR /F "usebackq delims=" %%L IN ("!TMPFILE!") DO (
        SET /A LINE_NUM+=1
        IF !LINE_NUM! EQU !CHOICE! (
            CALL SET "LINE=%%L"
            FOR /F "tokens=1* delims=|" %%A IN ("!LINE!") DO (
                ECHO %%B > "!TMP_SEL_FILE!"
            )
        )
    )
    ENDLOCAL

    REM Now read from file into persistent variable
    SET /P "YOUTUBE_URL=" < "%TEMP%\yt_selected_url.txt"
    DEL /F /Q "%TEMP%\yt_selected_url.txt" >nul
    ECHO Selected URL: %YOUTUBE_URL%
    GOTO :SEARCH_PLAYBACK
)

ECHO Invalid selection.
TIMEOUT /T 1 >nul
GOTO :CHOOSE_RESULT

:SEARCH_PLAYBACK
REM === Display only unique MP4 formats ===
CALL :SHOW_MP4_FORMATS

REM === Audio only option ===
SET "AUDIO_ONLY="
ECHO.
CHOICE /M "Audio only"
IF ERRORLEVEL 2 (
    SET "AUDIO_ONLY="
) ELSE (
    SET "AUDIO_ONLY=--audio-only"
)

REM === Video quality option ===
SET "VIDEO_QUALITY="
SET /P "VIDEO_QUALITY=Enter format code for MP4/3 quality (e.g. 137 for 1080p, leave blank for maximum quality): "

SET "OUTPUT_PATH=%TEMP%\yt_temp.mp4"
IF EXIST "%OUTPUT_PATH%" DEL /F /Q "%OUTPUT_PATH%"

IF NOT "%VIDEO_QUALITY%"=="" (
    REM Merge selected video with best audio (mp4 only)
    "%YTDLP_EXE%" -f "%VIDEO_QUALITY%+bestaudio[ext=mp4]" --merge-output-format mp4 -o "%OUTPUT_PATH%" "%YOUTUBE_URL%"
) ELSE (
    REM fallback to best mp4 with both audio/video
    "%YTDLP_EXE%" -f "bestvideo[ext=mp4]+bestaudio[ext=mp4]" --merge-output-format mp4 -o "%OUTPUT_PATH%" "%YOUTUBE_URL%"
)

IF EXIST "%OUTPUT_PATH%" (
    CLS
    ECHO Starting... ok.
    ECHO Rendering...
    ECHO -----------------------------------------------------
    start /wait "" "%MPV_EXE%" "%OUTPUT_PATH%" --vo=tct --no-config --terminal --really-quiet
    ECHO -----------------------------------------------------
    CALL :CLEANUP_TEMP
    ECHO Done.
    PAUSE
) ELSE (
    ECHO [ERR] Download or playback failed!
    CALL :CLEANUP_TEMP
    PAUSE
)
GOTO :MAIN_MENU

REM === MP4 format filter routine ===
:SHOW_MP4_FORMATS
ECHO.
ECHO [Available video-only MP4 formats (if you selected non-audio please use ID in this list):]
"%YTDLP_EXE%" -F "%YOUTUBE_URL%" | findstr /R /C:"^[ ]*[0-9][0-9]*.*mp4" | findstr /I "video only" || ECHO (None found.)

ECHO.
ECHO [Audio-only formats (if you selected audio-only please use ID in this list):]
"%YTDLP_EXE%" -F "%YOUTUBE_URL%" | findstr /R /C:"^[ ]*[0-9][0-9]*.*audio only" || ECHO (None found.)

ECHO.
EXIT /B


:PLAY_VIDEO
REM This section is no longer used, but kept for compatibility.
ECHO [ERR] This is fallback feature. Use URL and search flows instead.
GOTO :MAIN_MENU

:ABORT_PROGRAM
ECHO.
ECHO Setup failed. Please check your internet connection, tools, or permissions.
PAUSE
GOTO :EOF

:CLEANUP_TEMP
REM Skip if OUTPUT_PATH is undefined or blank
IF NOT DEFINED OUTPUT_PATH EXIT /B
IF "%OUTPUT_PATH%"=="" EXIT /B

REM Never delete this script
SET "SCRIPT_PATH=%~f0"
IF /I "%OUTPUT_PATH%"=="%SCRIPT_PATH%" (
    ECHO [WARN] Attempt to delete self detected. Skipping.
    EXIT /B
)

REM Only delete if the output path is in TEMP and matches known prefix
ECHO "%OUTPUT_PATH%" | findstr /I /C:"%TEMP%\yt_temp" >nul
IF ERRORLEVEL 1 (
    ECHO [WARN] Refusing to delete unexpected file: %OUTPUT_PATH%
    EXIT /B
)

FOR %%F IN ("%OUTPUT_PATH%") DO (
    IF EXIST "%%~F" DEL /F /Q "%%~F"
)

EXIT /B

:CLEAR-ALL-TEMP
DEL /F /Q "%LOCALAPPDATA%\Temp\*" >nul 2>&1
FOR /D %%D IN ("%LOCALAPPDATA%\Temp\*") DO RD /S /Q "%%D"
ECHO Done.
ECHO Press [Enter] to go back.
pause >nul
goto MAIN_MENU

:EOF
ENDLOCAL
EXIT /B
