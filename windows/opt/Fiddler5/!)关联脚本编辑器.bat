@ECHO OFF&(PUSHD "%~DP0")
(REG QUERY "HKU\S-1-5-19">NUL 2>&1)||(reg add "HKCU\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers" /f /v "%~dp0010Fiddler.exe" /d "~ RUNASADMIN" >NUL 2>NUL)
(REG QUERY "HKU\S-1-5-19">NUL 2>&1)||(powershell -Command "Start-Process '%~sdpnx0' -Verb RunAs" &&EXIT)

reg add "HKCU\SOFTWARE\Microsoft\Fiddler2" /f /v "CheckForUpdates" /d "False" >NUL 2>NUL
reg add "HKCU\SOFTWARE\Microsoft\Fiddler2" /f /v "JSEditor" /d "%~dp0ScriptEditor\FSE2.exe" >NUL 2>NUL
reg add "HKCU\SOFTWARE\Microsoft\Fiddler2\InstallerSettings" /f /v "InstallPath" /d "%~dp0\" >NUL 2>NUL
IF EXIST "%WinDir%\System32\CHOICE.exe" ( 
ECHO.&ECHO 关联完成 &TIMEOUT /t 2 >NUL & CLS & GOTO MENU
) ELSE ( 
ECHO.&ECHO 关联完成，任意键返回 &PAUSE>NUL&CLS&GOTO MENU) 