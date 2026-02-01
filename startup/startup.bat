@echo off
::powershell -WindowStyle Hidden -Command "cd 'C:\Users\kdhak\AppData\Local\Programs\Python\Python311\Lib\site-packages\open_webui'; Start-Process 'open-webui' -ArgumentList 'serve' -NoNewWindow -PassThru"
::timeout /t 5 /nobreak >nul
::powershell -WindowStyle Hidden -Command "Start-Process 'cmd' -ArgumentList '/c cd /d E:\AI\bolt.diy && pnpm run dev' -WindowStyle Hidden"
::timeout /t 5 /nobreak >nul
::powershell -WindowStyle Hidden -Command "Start-Process 'C:\nginx\nginx.exe' -WorkingDirectory 'C:\nginx' -NoNewWindow -PassThru"
::timeout /t 5 /nobreak >nul

:: Start ollama
::powershell -WindowStyle Hidden -Command "Start-Process 'ollama' -ArgumentList 'serve' -NoNewWindow -PassThru"
::timeout /t 5 /nobreak >nul

:: Start flask_bot_manager
powershell -WindowStyle Hidden -Command "Start-Process cmd.exe -ArgumentList '/c cd /d \"C:\Apps\flask_bot_manager\" && venv\Scripts\python app.py' -WindowStyle Hidden"
timeout /t 5 /nobreak >nul

exit
