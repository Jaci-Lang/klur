@echo off
setlocal
set "KLUR_DIR=%~dp0.."
where luau >nul 2>nul
if %errorlevel% equ 0 (
    set "LUAU_BIN=luau"
) else if exist "%KLUR_DIR%\..\build\Release\luau.exe" (
    set "LUAU_BIN=%KLUR_DIR%\..\build\Release\luau.exe"
) else if exist "%KLUR_DIR%\build\Release\luau.exe" (
    set "LUAU_BIN=%KLUR_DIR%\build\Release\luau.exe"
) else if exist "%USERPROFILE%\.klur\bin\luau.exe" (
    set "LUAU_BIN=%USERPROFILE%\.klur\bin\luau.exe"
) else (
    echo Error: Jaci/Luau runtime binary not found in PATH or build directory. >&2
    exit /b 1
)

"%LUAU_BIN%" "%KLUR_DIR%\src\init.luau" -a %*
endlocal
