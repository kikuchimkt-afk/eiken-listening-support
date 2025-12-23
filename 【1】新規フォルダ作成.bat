@echo off
chcp 65001 > nul
echo 準備中...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0STEP1_新規フォルダ作成.ps1"
if %ERRORLEVEL% NEQ 0 (
    echo エラーが発生しました。
    pause
)
