@echo off
setlocal enabledelayedexpansion
set "CHARS=ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
set "RANDSTR="
for /L %%i in (1,1,8) do (
    set /a "idx=!random! %% 62"
    for %%j in (!idx!) do set "RANDSTR=!RANDSTR!!CHARS:~%%j,1!"
)
echo windows_!RANDSTR!