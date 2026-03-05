@echo off
echo ========================================
echo   PRE-PUSH SECURITY CHECK
echo ========================================
echo.

set ERROR=0

echo [1/5] Checking if .env is staged...
git diff --cached --name-only | findstr /E /C:".env" >nul
if %errorlevel% equ 0 (
    echo [ERROR] .env file is staged! Run: git reset HEAD .env
    set ERROR=1
) else (
    echo [OK] .env is not staged
)

echo.
echo [2/5] Checking if google-services.json is staged...
git diff --cached --name-only | findstr /C:"google-services.json" >nul
if %errorlevel% equ 0 (
    echo [ERROR] google-services.json is staged!
    set ERROR=1
) else (
    echo [OK] google-services.json is not staged
)

echo.
echo [3/5] Checking for hardcoded API keys in code files...
git diff --cached -- "*.dart" "*.java" "*.kt" "*.swift" | findstr /C:"AIzaSy" >nul
if %errorlevel% equ 0 (
    echo [ERROR] Hardcoded API key found in code!
    set ERROR=1
) else (
    echo [OK] No hardcoded API keys in code
)

echo.
echo [4/5] Verifying .env is in .gitignore...
findstr /C:".env" .gitignore >nul
if %errorlevel% equ 0 (
    echo [OK] .env is in .gitignore
) else (
    echo [ERROR] .env is NOT in .gitignore!
    set ERROR=1
)

echo.
echo [5/5] Checking if .env file exists locally...
if exist ".env" (
    echo [OK] .env file exists locally
) else (
    echo [WARNING] .env file not found
)

echo.
echo ========================================
if %ERROR% equ 1 (
    echo   FAILED - Fix errors before pushing!
    echo ========================================
    exit /b 1
) else (
    echo   PASSED - Safe to push!
    echo ========================================
    exit /b 0
)
