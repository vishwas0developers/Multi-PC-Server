@echo off

:: ------------------------------
:: 1) Start GLM Host silently (UAC → YES/NO)
:: ------------------------------
powershell -WindowStyle Hidden -Command ^
"Start-Process 'D:\AI_Tools\Multi-PC Server\Host_Run\start_host_server.bat' -Verb RunAs -WindowStyle Hidden"
timeout /t 4 /nobreak >nul

exit
