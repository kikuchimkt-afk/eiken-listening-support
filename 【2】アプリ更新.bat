@echo off
chcp 65001 > nul
echo 更新中...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0STEP2_アプリ更新.ps1"
if %ERRORLEVEL% NEQ 0 (
    echo エラーが発生しました。
    pause
)
